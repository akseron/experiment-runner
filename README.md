## Requirements

The framework has been tested with Python3 version 3.8, but should also work with any higher version. It has been tested under Linux and macOS. It does **not** work on Windows (at the moment).

To get started:

```bash
git clone https://github.com/S2-group/experiment-runner.git
cd experiment-runner/
pip install -r requirements.txt
```

To verify installation, run:

```bash
python experiment-runner/ examples/hello-world/RunnerConfig.py
```

Additionally run the following commands to install necessary packages:
```bash
curl https://sh.rustup.rs -sSf | sh
"${SHELL}" <(curl -L micro.mamba.pm/install.sh)
apt install tesseract-ocr
apt-get install ccache
```
Optionally if you are running the EnergiBridge configuration:
```bash
sudo chgrp -R $USER /dev/cpu/*/msr;
sudo chmod g+r /dev/cpu/*/msr;
```

## Running

In this section, we assume as the current working directory, the root directory of the project.


Run the following commands to create a virtual environment to run our programs in:
```bash
micromamba create -p .venv 'python==3.12'
micromamba activate .venv
```

For the run itself, first let the laptop sit for 30 minutes, and afterwards just either of the following:
```bash
sudo /home/username/micromamba/envs/.venv/bin/python experiment-runner RunnerConfig_EnergiBridge.py
```

```bash
sudo /home/username/micromamba/envs/.venv/bin/python experiment-runner RunnerConfig_PowerJoular.py
```
