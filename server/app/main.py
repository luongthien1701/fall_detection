import asyncio
import websockets
import uvicorn
from fastapi import FastAPI
from app.api.routes import router
from app.websocket.ws_handler import handler

app = FastAPI()
app.include_router(router)

async def start_ws():
    async with websockets.serve(handler, "0.0.0.0", 8181):
        await asyncio.Future()

async def start_api():
    config = uvicorn.Config(app, host="0.0.0.0", port=8000)
    server = uvicorn.Server(config)
    await server.serve()

async def main():
    await asyncio.gather(
        start_ws(),
        start_api()
    )

if __name__ == "__main__":
    asyncio.run(main())