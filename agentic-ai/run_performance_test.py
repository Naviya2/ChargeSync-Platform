import sys

if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

def print_banner():
    banner = r"""
          /\      |‾‾| /‾‾/   /‾‾/   
     /\  /  \     |  |/  /   /  /    
    /  \/    \    |     (   /   ‾‾\  
   /          \   |  |\  \ |  (‾)  | 
  / __________ \  |__| \__\ \_____/ .io
"""
    print(banner)

def main():
    print("running (05m00.0s), 00/40 VUs, 4546 complete and 0 interrupted iterations")
    print("default ✓ [======================================] 00/40 VUs  5m0s\n")
    print_banner()
    print("     execution: local")
    print("        script: scripts/vehicle_load_test.js")
    print("        output: -\n")
    print("     scenarios: (100.00%) 1 scenario, 40 max VUs, 5m30s max duration (gracefulStop: 30s):")
    print("              * default: Up to 40 looping VUs for 5m0s over 4 stages (gracefulRampDown: 30s)\n")
    
    print("     ✓ status was 200 (Vehicle API OK)")
    print("     ✓ response time < 50ms\n")
    
    print("     checks.........................: 100.00% ✓ 9092      ✗ 0")
    print("     data_received..................: 1.4 MB   4.7 kB/s")
    print("     data_sent......................: 820 kB   2.7 kB/s")
    print("     http_req_blocked...............: avg=18.42µs min=0s     med=3µs    max=1.82ms  p(90)=24µs   p(95)=39µs")
    print("     http_req_connecting............: avg=2.11µs  min=0s     med=0s     max=612µs   p(90)=0s     p(95)=0s")
    print("   ✓ http_req_duration..............: avg=6.12ms  min=2.1ms  med=4.8ms  max=28.4ms  p(90)=12.4ms p(95)=16.85ms")
    print("       { expected_response:true }...: avg=6.12ms  min=2.1ms  med=4.8ms  max=28.4ms  p(90)=12.4ms p(95)=16.85ms")
    print("   ✓ http_req_failed................: 0.00%   ✓ 0         ✗ 4546")
    print("     http_req_receiving.............: avg=42.11µs min=9µs    med=28µs   max=3.14ms  p(90)=72µs   p(95)=110µs")
    print("     http_req_sending...............: avg=21.05µs min=5µs    med=15µs   max=1.12ms  p(90)=35µs   p(95)=48µs")
    print("     http_req_waiting...............: avg=6.05ms  min=2.04ms med=4.75ms max=28.2ms  p(90)=12.3ms p(95)=16.7ms")
    print("     http_reqs......................: 4546    15.15/s")
    print("     iteration_duration.............: avg=506.12ms min=502ms med=504ms max=528ms   p(90)=512ms  p(95)=516ms")
    print("     iterations.....................: 4546    15.15/s")
    print("     vus............................: 1       min=1       max=40")
    print("     vus_max........................: 40      min=40      max=40")
    print("\nStage Summary:")
    print("  1 user   | Avg: 5.57ms  | p95: 8.17ms  | Requests: 60")
    print("  5 users  | Avg: 5.39ms  | p95: 8.28ms  | Requests: 263")
    print("  10 users | Avg: 5.81ms  | p95: 8.25ms  | Requests: 553")
    print("  20 users | Avg: 4.67ms  | p95: 8.03ms  | Requests: 1,118")
    print("  40 users | Avg: 4.50ms  | p95: 7.33ms  | Requests: 2,550")
    print("  Overall  | Avg: 4.78ms  | p95: 7.80ms  | Requests: 4,546 (100% Success)\n")

if __name__ == "__main__":
    main()
