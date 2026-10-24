from pywinauto import Desktop
from pathlib import Path
import loggerric2 as lr
import time, os

VERSION = '1.2'

OUTPUT = Path(os.path.dirname(__file__) + '/ghub_last_msg.txt')
POLL_INTERVAL = 0.1

def read_control(control) -> str:
    """
    **Try the accessible text interfaces supported by the control.**
    
    *Parameters*:
    - `control` (pywinauto.controls.uia_controls.EditWrapper): The control to try.
    
    *Returns*:
    - (str): The value from the attempted method if any.
    """

    for method_name in ('get_value', 'window_text', 'text_block'):
        try:
            value = getattr(control, method_name)()
            if isinstance(value, str):
                return value
        except Exception: continue

        return None

def find_console() -> tuple:
    """
    **Retrieve all windows that pywinauto can see and attempt to locate GHUB console.**
    
    *Returns*:
    - (tuple[pywinauto.controls.uiawrapper.UIAWrapper,
       pywinauto.controls.uia_controls.EditWrapper]): The found window and control.
    """

    desktop = Desktop(backend='uia')
    for window in desktop.windows():
        title = window.window_text().lower()
        if 'ghub' not in title and 'g hub' not in title: continue

        try:
            controls = window.descendants(control_type='Edit')
        except Exception: continue

        for control in controls:
            try:
                if control.is_editable(): continue
            except Exception: continue

            return window, control

    return None, None

def latest_line(text:str) -> str:
    """
    **Return the latest non-empty line in a text snapshot.**
    
    *Parameters*:
    - `text` (str): Input text to search.
    
    *Returns*:
    - (str): The latest line from the input text.
    """

    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return lines[-1] if lines else ''

def main():
    """
    **Main entrypoint.**
    """

    lr.Log.info(f'=== PUBG RC Overlay - GHUB Injector v{VERSION} ===')
    lr.Log.debug(f'Logging to file: {OUTPUT}')

    # Take a baseline snapshot. Existing lines are not written.
    previous = None

    while previous is None:
        _, control = find_console()

        if control is not None:
            previous = read_control(control)

        if previous is None:
            print('Waiting for the G HUB console control...')
            time.sleep(1)

    lr.Log.info('Monitoring for new console output...')

    with OUTPUT.open('w', encoding='utf-8') as out:
        out.write('')
        out.flush()

    control = None
    while True:
        try:
            # Find the console only when we don't have a usable reference.
            if control is None:
                _, control = find_console()

                if control is None:
                    time.sleep(0.5)
                    continue

            current = read_control(control)

            if current is None:
                # The cached reference may no longer be usable.
                control = None
                time.sleep(0.2)
                continue

            if current != previous:
                if current.startswith(previous):
                    added = current[len(previous):]
                else:
                    # Console contents were cleared or replaced.
                    added = current

                line = latest_line(added)

                if line:
                    with OUTPUT.open('w', encoding='utf-8') as out:
                        out.write(line)

                    # Log only when new output appears.
                    lr.Log.debug(f'New console line: {line}')

                previous = current

            time.sleep(POLL_INTERVAL)

        except KeyboardInterrupt:
            lr.Log.warn('Keyboard interrupt detected. Daemon stopped!')
            break

        except Exception as e:
            lr.Log.error(f'Unexpected automation error: {e}')
            control = None
            time.sleep(0.2)

if __name__ == '__main__':
    lr.LogManager.set_state('disabled')

    main()
