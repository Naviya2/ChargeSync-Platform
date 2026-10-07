from pathlib import Path

from config import Settings


def test_env_file_does_not_depend_on_launch_directory(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    env_file = Path(Settings.model_config['env_file'])
    assert env_file.is_absolute()
    assert env_file.parent == Path(__file__).resolve().parents[1]
