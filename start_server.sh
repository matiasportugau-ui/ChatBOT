#!/bin/bash
cd "$(dirname "$0")"
source .venv/bin/activate
rasa run --model models/20251109-214427-visible-reservoir.tar.gz --enable-api --cors '*' --port 5005
