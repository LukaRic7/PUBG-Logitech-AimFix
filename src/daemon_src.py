import websocket, json, requests, subprocess, threading, time, sys, os
import loggerric as lr

SUICIDE = False
FETCH_DELAY = 0.1
FLUSH_TIMEOUT = 1

def get_app_path(filename:str) -> str:
    """
    **Returns a path to a file located in the same directory. Compile safe.**
    
    *Parameters*:
    - `filename` (str): Name of file in the same dir as the .exe or .py
    
    *Returns*:
    - (str): Total file path
    """

    if getattr(sys, 'frozen', False):
        base_path = os.path.dirname(sys.executable)
    else:
        base_path = os.path.dirname(os.path.abspath(__file__))

    return os.path.join(base_path, filename)

def kill_ghub():
    """
    **Kill all processes related to Logitech GHUB.**
    """

    processes = [
        'lghub.exe', 'lghub_agent.exe',
        'lghub_updater.exe', 'lghub_system_tray.exe'
    ]

    try:
        for proc in processes:
            subprocess.run(
                ['taskkill', '/F', '/IM', proc, '/T'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
    except Exception as e:
        lr.Log.error(f'Error occurred trying to kill GHUB: {e}')
        exit()

    lr.Log.info('GHUB processes successfully killed!')

def launch_injected_ghub(ghub_path:str='C:/Program Files/LGHUB/lghub.exe'):
    """
    **Launch GHUB injecting it with electron flags.**
    
    Exposes a websocket endpoint where javascript code can be executed.

    *Parameters*:
    - `ghub_path` (str): The file path to GHUB.
    """

    flags = [
        '--remote-debugging-port=9222',
        '--remote-allow-origins=http://localhost:9222'
    ]
    
    try:
        subprocess.Popen([ghub_path] + flags, stdout=subprocess.DEVNULL)
    except Exception as e:
        lr.Log.error(f'Error occurred trying to launch injected GHUB: {e}')
        exit()

    lr.Log.info('Launched injected GHUB successfully!')

def grab_ghub_websocket_url() -> str:
    """
    **Grab the GHUB websocket URL from the flag injected GHUB's endpoint.**
    
    *Returns*:
    - (str): The websocket URL, none if the endpoint is not open (not injected).
    """

    try:
        response = requests.get('http://localhost:9222/json')
        if not response.ok:
            lr.Log.error('GHUB endpoint did not return ok. [{}]: {}'.format(
                response.status_code, response.reason
            ))
            exit()
        
        data:list[dict] = response.json()
        for frame in data:
            if frame.get('title') == 'G HUB':
                return frame.get('webSocketDebuggerUrl')
    except requests.exceptions.ConnectionError:
        lr.Log.warn('Injected GHUB is not running!')
        return

def start_websocket_listen(url:str, new_msg_callback):
    """
    **Start listening and injecting javascript into the G HUB renderer.**
    
    *Parameters*:
    - `url` (str): URL of the websocket.
    - `new_msg_callback` (str): Function to call when a new message appears.
    """

    ws = websocket.WebSocket()
    ws.connect(url)
    lr.Log.info('Connected to the GHUB renderer!')

    ws.send(json.dumps({ 'id': 1, 'method': 'Runtime.enable' }))
    ws.send(json.dumps({ 'id': 2, 'method': 'Console.enable' }))

    def worker():
        html = """
        (() => {
            const el = document.querySelector('.console-container textarea');

            if (!el) {
                console.log("NO_CONSOLE_FOUND");
                return;
            }

            const lines = el.value.toString().split("\\n").filter(Boolean);
            const last = lines[lines.length - 1];

            console.log(last);
        })();
        """.replace('\t', '').replace('\n', '')

        while not SUICIDE:
            ws.send(json.dumps({
                'id': 3,
                'method': 'Runtime.evaluate',
                'params': { 'expression': html }
            }))
            
            time.sleep(FETCH_DELAY)

    thread = threading.Thread(target=worker)
    thread.start()
    lr.Log.info('Started javscript injection thread worker!')

    last_msg = ''

    start = time.time()
    while not SUICIDE:
        message = ws.recv()
        if time.time() - start < FLUSH_TIMEOUT: continue

        event:dict[str, dict[str, dict]] = json.loads(message)

        if event.get('method') == 'Console.messageAdded':
            msg_text = event.get('params').get('message').get('text')

            if last_msg != msg_text:
                last_msg = msg_text
                new_msg_callback(msg_text)

def on_new_msg(msg:str):
    """
    **Called by websocket listener when a new message appears.**
    
    *Parameters*:
    - `msg` (str): The new message.
    """

    path = get_app_path('ghub_last_msg.txt')
    with open(path, 'w') as file:
        file.write(msg)

def main():
    """
    **Main entrypoint.**
    """

    url = grab_ghub_websocket_url()
    if not url:
        kill_ghub()
        launch_injected_ghub()
        url = grab_ghub_websocket_url()

    lr.Log.debug(f'Retrieved URL: {url}')

    start_websocket_listen(url, on_new_msg)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        lr.Log.info('Keyboard interrupt detected, closing!')
        SUICIDE = True
        exit()