import asyncio
import websockets
import re

async def main():
    ws = await websockets.connect("wss://irc-ws.chat.twitch.tv:443")
    #await ws.send("CAP REQ :twitch.tv/tags twitch.tv/commands")
    await ws.send("NICK justinfan1234")
    await ws.send("JOIN #ludwig")
    
    while True:
        msg = await ws.recv()
        if msg.startswith("PING"):
            await ws.send("PONG")
        else:
            print(msg)
            #m = re.search(r"@?[^\s:]*\s*:(\w+)![^:]+:(.+)", msg)
            #if m:
            #    print(f"{m.group(1)}: {m.group(2)}")

asyncio.run(main())
