import math
from typing import List, Tuple, Optional
from models.compatibility_models import (
    VehicleInput,
    StationInput,
    ChargerInput,
    ChargerCompatibilityDetail,
    AlternativeStationSuggestion,
    CompatibilityRequest,
    CompatibilityResponse,
    BatchCompatibilityRequest,
    BatchCompatibilityResponse,
    BatchStationScore,
)
from config import settings

class VehicleCompatibilityAgent:
    """
    Function 1: Vehicle & AI Compatibility Discovery Agent.
    
    Responsibilities:
    - Validates hardware socket compatibility between EV profile and charging station units.
    - Computes effective charging power based on vehicle intake limits and charger outputs.
    - Calculates realistic 10% -> 80% charge duration benchmarks.
    - Produces a multi-factor compatibility score (0 - 100%).
    - Detects power bottlenecks and generates proactive warnings.
    - Autonomously discovers and ranks alternative compatible stations if target station is unsuitable.
    """

    def __init__(self):
        self.charge_delta_percent = settings.DEFAULT_CHARGE_DELTA_PERCENT

    @staticmethod
    def normalize_connector(connector: str) -> str:
        if not connector:
            return ""
        norm = connector.strip().upper().replace(" ", "").replace("-", "").replace("/", "")
        if norm in ["TYPE2", "MENNEKES", "IEC62196"]:
            return "Type2"
        if norm in ["CCS2", "CCSCOMBO2", "COMBO2"]:
            return "CCS2"
        if norm in ["NACS", "TESLA", "SAEJ3400"]:
            return "NACS"
        if norm in ["CHADEMO"]:
            return "CHAdeMO"
        if norm in ["GBT", "GUOBIAO"]:
            return "GBT"
        if norm in ["MCS", "MEGAWATT"]:
            return "MCS"
        return connector.strip()

    def evaluate_charger(
        self,
        vehicle: VehicleInput,
        charger: ChargerInput
    ) -> ChargerCompatibilityDetail:
        veh_conn = self.normalize_connector(vehicle.connector)
        chg_conn = self.normalize_connector(charger.connector)
        
        is_compatible = (veh_conn.lower() == chg_conn.lower())
        
        effective_power = 0.0
        est_minutes: Optional[float] = None
        est_formatted: Optional[str] = None

        if is_compatible and charger.power_kw > 0 and vehicle.max_charge_rate_kw > 0:
            effective_power = min(charger.power_kw, vehicle.max_charge_rate_kw)
            
            # Duration (hours) = (Battery capacity * 0.70) / effective power (kW)
            hours = (vehicle.battery_capacity_kwh * self.charge_delta_percent) / effective_power
            mins = hours * 60.0
            est_minutes = round(mins, 1)
            
            total_mins = int(round(mins))
            h = total_mins // 60
            m = total_mins % 60
            if h > 0:
                est_formatted = f"{h}h {m}m (10-80%)"
            else:
                est_formatted = f"{total_mins} mins (10-80%)"

        return ChargerCompatibilityDetail(
            charger_id=charger.charger_id,
            identifier=charger.identifier,
            connector=charger.connector,
            power_kw=charger.power_kw,
            is_compatible=is_compatible,
            effective_power_kw=round(effective_power, 1),
            estimated_charge_time_minutes=est_minutes,
            estimated_charge_time_formatted=est_formatted,
        )

    def evaluate_station(
        self,
        vehicle: VehicleInput,
        station: StationInput
    ) -> Tuple[
        bool,
        int,
        Optional[str],
        float,
        Optional[float],
        Optional[str],
        List[ChargerCompatibilityDetail],
        List[str],
    ]:
        evaluated_chargers = [
            self.evaluate_charger(vehicle, chg) for chg in station.chargers
        ]

        compatible_chargers = [c for c in evaluated_chargers if c.is_compatible]
        is_compatible = len(compatible_chargers) > 0
        warnings: List[str] = []

        if not is_compatible:
            veh_conn = self.normalize_connector(vehicle.connector)
            available_conns = list({c.connector for c in station.chargers})
            warnings.append(
                f"Connector mismatch: Vehicle requires {veh_conn}, but station only provides {', '.join(available_conns) if available_conns else 'no chargers'}."
            )
            return (
                False,
                0,
                None,
                0.0,
                None,
                None,
                evaluated_chargers,
                warnings,
            )

        # Select the best charger (highest effective charging power)
        best_charger = max(compatible_chargers, key=lambda c: c.effective_power_kw)
        best_power = best_charger.effective_power_kw
        best_mins = best_charger.estimated_charge_time_minutes
        best_formatted = best_charger.estimated_charge_time_formatted

        # Compute multi-factor compatibility score (0 - 100)
        # 1. Base match: 60 pts
        # 2. Power efficiency: Up to 20 pts based on power delivery vs vehicle capacity
        power_fit_score = min(20.0, (best_charger.power_kw / vehicle.max_charge_rate_kw) * 20.0)
        
        # 3. Proximity score: Up to 20 pts (max 20 minus distance)
        dist = station.distance_km or 0.0
        proximity_score = max(0.0, 20.0 - dist)

        score = int(round(60.0 + power_fit_score + proximity_score))
        score = min(100, max(0, score))

        # Check for power bottleneck warnings
        if best_charger.power_kw < (vehicle.max_charge_rate_kw * 0.65):
            warnings.append(
                f"Power Bottleneck: Charger output ({best_charger.power_kw:.0f} kW) is significantly below vehicle max intake ({vehicle.max_charge_rate_kw:.0f} kW). Charging will take longer."
            )
        elif best_charger.power_kw >= vehicle.max_charge_rate_kw:
            warnings.append(
                f"Optimal Power: Charger delivers {best_charger.power_kw:.0f} kW, maximizing your vehicle's peak charging speed ({vehicle.max_charge_rate_kw:.0f} kW)."
            )

        if "TYPE2" in best_charger.connector.upper() and best_charger.power_kw <= 22:
            warnings.append("AC Destination Charger: Best suited for extended parking or overnight stops.")

        return (
            True,
            score,
            best_charger.charger_id,
            best_power,
            best_mins,
            best_formatted,
            evaluated_chargers,
            warnings,
        )

    def discover_alternatives(
        self,
        vehicle: VehicleInput,
        candidate_stations: List[StationInput],
        current_station_id: Optional[str] = None
    ) -> List[AlternativeStationSuggestion]:
        suggestions: List[AlternativeStationSuggestion] = []

        for st in candidate_stations:
            if current_station_id and st.station_id == current_station_id:
                continue

            (
                is_comp,
                score,
                best_id,
                best_power,
                best_mins,
                best_fmt,
                _,
                _,
            ) = self.evaluate_station(vehicle, st)

            if is_comp and score >= 40:
                dist_str = f"{st.distance_km:.1f} km away" if st.distance_km is not None else "Nearby"
                reason = f"Provides compatible {vehicle.connector} at {best_power:.0f} kW ({best_fmt or 'Fast Charge'}), {dist_str}."
                
                suggestions.append(
                    AlternativeStationSuggestion(
                        station_id=st.station_id,
                        name=st.name,
                        address=st.address,
                        distance_km=st.distance_km or 0.0,
                        compatibility_score=score,
                        best_power_kw=best_power,
                        estimated_charge_time_formatted=best_fmt,
                        reason=reason,
                    )
                )

        # Sort alternatives by score descending, then distance ascending
        suggestions.sort(key=lambda s: (-s.compatibility_score, s.distance_km))
        return suggestions[:3]

    def generate_ai_insight(
        self,
        vehicle: VehicleInput,
        target_station: StationInput,
        is_compatible: bool,
        score: int,
        effective_power: float,
        formatted_time: Optional[str],
        warnings: List[str]
    ) -> str:
        """
        Generates a concise natural language explanation summarizing the compatibility assessment.
        """
        if not is_compatible:
            return (
                f"Incompatibility Alert: {target_station.name} does not have a {vehicle.connector} socket matching your {vehicle.make} {vehicle.model}. Please check the recommended alternative stations below."
            )

        summary_parts = [
            f"{vehicle.make} {vehicle.model} is fully compatible with {target_station.name} (Score: {score}/100)."
        ]
        
        if formatted_time:
            summary_parts.append(
                f"Estimated fast-charge time from 10% to 80% is {formatted_time} at an effective rate of {effective_power:.0f} kW."
            )

        if warnings:
            summary_parts.append(f"Note: {warnings[0]}")

        return " ".join(summary_parts)

    def evaluate(self, request: CompatibilityRequest) -> CompatibilityResponse:
        (
            is_compatible,
            score,
            best_charger_id,
            effective_power,
            est_minutes,
            est_formatted,
            chargers,
            warnings,
        ) = self.evaluate_station(request.vehicle, request.target_station)

        # If incompatible or low score, find alternatives
        alternatives: List[AlternativeStationSuggestion] = []
        if (not is_compatible or score < 60) and request.candidate_alternative_stations:
            alternatives = self.discover_alternatives(
                request.vehicle,
                request.candidate_alternative_stations,
                current_station_id=request.target_station.station_id,
            )

        insight = self.generate_ai_insight(
            vehicle=request.vehicle,
            target_station=request.target_station,
            is_compatible=is_compatible,
            score=score,
            effective_power=effective_power,
            formatted_time=est_formatted,
            warnings=warnings,
        )

        return CompatibilityResponse(
            is_compatible=is_compatible,
            compatibility_score=score,
            best_charger_id=best_charger_id,
            effective_charging_power_kw=effective_power,
            estimated_charge_time_minutes=est_minutes,
            estimated_charge_time_formatted=est_formatted,
            chargers=chargers,
            warnings=warnings,
            suggested_alternatives=alternatives,
            ai_insight=insight,
        )

    def batch_evaluate(self, request: BatchCompatibilityRequest) -> BatchCompatibilityResponse:
        results: List[BatchStationScore] = []

        for st in request.stations:
            (
                is_comp,
                score,
                _,
                best_power,
                _,
                best_fmt,
                evaluated_chargers,
                _,
            ) = self.evaluate_station(request.vehicle, st)

            results.append(
                BatchStationScore(
                    station_id=st.station_id,
                    name=st.name,
                    distance_km=st.distance_km or 0.0,
                    is_compatible=is_comp,
                    compatibility_score=score,
                    effective_power_kw=best_power,
                    estimated_charge_time_formatted=best_fmt,
                    chargers=evaluated_chargers,
                )
            )

        # Sort batch results: compatible first, then highest score, then closest distance
        results.sort(key=lambda s: (not s.is_compatible, -s.compatibility_score, s.distance_km))

        summary = f"{request.vehicle.make} {request.vehicle.model} ({request.vehicle.connector}, {request.vehicle.battery_capacity_kwh}kWh, {request.vehicle.max_charge_rate_kw}kW)"
        return BatchCompatibilityResponse(
            vehicle_summary=summary,
            stations=results,
        )
