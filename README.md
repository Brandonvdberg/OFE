# Objection File Extractor

Downloads directories and file recursively through Objection while maintaining the original file structure*
Supports both Android and iOS patched apps.

## Why?

Sometimes you can only use a Frida gadget to interact with an app. Objection and other tools do not support recursive download. While manually downloading a few hunderd files sounds like a fun time, this tool should make the process a lot less painful.

## Requirements

Make sure that Objection and Frida_tools have been installed.

## How to use

1. Make sure the app is running on the device and that you can run frida-ps. (You dont need to launch it through objection, you can just open it normally)
2. Update the variables in the script. <------------------------ This
3. Run the script
4. Go make a coffee
5. Profit.
