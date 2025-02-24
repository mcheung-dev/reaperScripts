# @author mcheung
# @version 1.0 
##################### -- reminder to install pyimgui, in command prompt "pip install imgui"
import asyncio
from waapi import WaapiClient, CannotConnectToWaapiException
import threading
import queue
from reaper_python import *
####################### --- import all files from wwise logic 
def waapi_thread(result_queue):
    try:
        async_loop = asyncio.new_event_loop()
        asyncio.set_event_loop(async_loop)

        with WaapiClient() as client:
            # Get selected object (should be a Work Unit)
            args = {
                "options": {
                    "return": ["id", "type", "name", "path"]
                }
            }
            
            selected_objs = client.call("ak.wwise.ui.getSelectedObjects", args)["objects"]

            # Ensure a Work Unit is selected
            work_unit_ids = [obj["id"] for obj in selected_objs if obj["type"] == "WorkUnit"]

            if not work_unit_ids:
                RPR_ShowConsoleMsg("Error: Please select a Work Unit!\n")
                result_queue.put([])  # Prevent UnboundLocalError
                return  # Stop execution

            # Get all descendants under the Work Unit
            query_args = {
                "from": {
                    "id": work_unit_ids
                },
                "transform": [
                    {"select": ["descendants"]}
                ],
                "options": {
                    "return": ["id", "type", "sound:originalWavFilePath"]
                }
            }
            
            all_objects = client.call("ak.wwise.core.object.get", query_args)["return"]

            # Dictionary to track imported sounds and prevent duplicates
            imported_sound_paths = set()

            # Function to extract all playable Sound objects
            def get_all_sounds(obj_list):
                final_sounds = []
                for obj in obj_list:
                    if obj["type"] == "Sound" and "sound:originalWavFilePath" in obj:
                        wav_path = obj["sound:originalWavFilePath"]
                        if wav_path not in imported_sound_paths:
                            imported_sound_paths.add(wav_path)  # Track imported sounds
                            final_sounds.append(wav_path)
                    elif obj["type"] in ["BlendContainer", "RandomSequenceContainer", "ActorMixer"]:
                        # Get ALL children of the container
                        sub_query = {
                            "from": {"id": [obj["id"]]},
                            "transform": [{"select": ["descendants"]}],
                            "options": {"return": ["id", "type", "sound:originalWavFilePath"]}
                        }
                        sub_objects = client.call("ak.wwise.core.object.get", sub_query)["return"]
                        final_sounds.extend(get_all_sounds(sub_objects))  # Recursively get sounds
                return final_sounds

            # Collect all final Sound objects
            sound_file_paths = get_all_sounds(all_objects)

            result_queue.put(sound_file_paths)  # Ensure something is always put in the queue
            client.disconnect()

    except Exception as e:
        RPR_ShowConsoleMsg(f"Error: {e}\n")
        result_queue.put([])  # Prevent crash by putting an empty list
    finally:
        if client:
            client.disconnect()  # Ensure WAAPI disconnects properly

def main():
    result_queue = queue.Queue()
    t = threading.Thread(target=waapi_thread, args=(result_queue,))
    t.start()
    t.join()
    
    # Ensure filepath_list is always initialized
    filepath_list = result_queue.get() if not result_queue.empty() else []

    if not filepath_list:
        RPR_ShowConsoleMsg("No sound files found in the selected Work Unit!\n")
    else:
        for filepath in filepath_list:
            RPR_InsertMedia(filepath, 0)

if __name__ == "__main__":
    main()
########################


