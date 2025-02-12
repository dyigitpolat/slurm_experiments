#!/bin/bash
ENV_DIR=venv

if [ ! -d "$ENV_DIR" ]; then
    echo "creating remote venv in $ENV_DIR..."
    python3 -m venv $ENV_DIR
fi

echo "activating remote venv..."
source $ENV_DIR/bin/activate

echo "upgrading pip and installing dependencies..."
pip install --upgrade pip
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
else
    pip install torch torchvision
fi

echo "remote env setup complete."
