# Developing Zishu on non-IOS

Development on iOS is rather simple; however, some libraries are unavailable on Linux and Windows. This guide should assist in setup for Linux and Windows developers.

## Codebase Setup

Fork Zishu [here](https://github.com/Grosess/zishu/fork) and pull your forked repo onto your local machine.

## Android Studios

Android Studios provides a layer of abstraction and support in terms of package availability. Downloading Android Studios [here](https://developer.android.com/studio) or through another method is required.

Open zishu/android as the directory instead of zishu
![File or Project Opener Window](open_file_or_project.png)

## Running an Emulator

On the right side of the screen, click "Device Manager"
![alt text](device_manager.png)

Click the `+` sign to add a new emulator
![alt text](create_virtual_device.png)

Choose medium phone and click next
![alt text](medium_phone.png)

Click Finish
![alt text](add_device.png)

## Configuring the Emulator

On the right side of the screen, click "Device Manager"
![alt text](device_manager.png)

For your emulator, click the three vertical dots and click "Edit"
![alt text](edit_emulator.png)

Here are some changes that are recommended

- Change Graphics acceleration to Hardware
- Update RAM to 8GB
- Update VM heap size to 2GB

![alt text](emulator_configurations.png)
