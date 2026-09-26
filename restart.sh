#!/bin/bash
echo "Stopping old processes..."
killall uvicorn 2>/dev/null
killall ngrok 2>/dev/null
sleep 2

echo "Starting FastAPI server on port 8000..."
nohup ./.venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --reload > uvicorn.log 2>&1 &

echo "Starting ngrok tunnel..."
nohup ./ngrok http --url=nonrebellious-homer-bigamously.ngrok-free.dev 8000 > ngrok.log 2>&1 &

echo "----------------------------------------"
echo "Restart complete!"
echo "Uvicorn logs: tail -f uvicorn.log"
echo "Ngrok logs: tail -f ngrok.log"
echo "----------------------------------------"
