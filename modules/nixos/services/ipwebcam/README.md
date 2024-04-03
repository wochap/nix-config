### [IP Webcam](https://play.google.com/store/apps/details?id=com.pas.webcam)

#### Obs

1. Setup `IP Webcam` on your phone

1. Forward the output of `IP Webcam` to the host

   ```sh
   $ adb devices

   $ adb forward tcp:<host_port> tcp:<device_port>

   # e.g.
   $ adb forward tcp:3333 tcp:8080
   ```

1. Setup `Obs`

   Create a `Media Source` with input value: `http://<ip>:<port>/videofeed`, e.g. `http://localhost:3333/videofeed`

1. TODO: Start virtual camera instructions

### [ffmpeg](https://wiki.archlinux.org/title/V4l2loopback#Using_an_Android_device_as_webcam)

1. Setup `IP Webcam` on your phone

1. Forward the output of `IP Webcam` to the host

   ```sh
   $ adb wait-for-usb-device

   $ adb devices

   $ adb forward tcp:<host_port> tcp:<device_port>

   # e.g.
   $ adb forward tcp:3333 tcp:8080
   ```

1. Setup `ffmpeg`

   ```sh
   $ ffmpeg -i http://127.0.0.1:<port>/video -vf format=yuv420p -f v4l2 /dev/video0

   # e.g.
   $ ffmpeg -i http://127.0.0.1:3333/video -vf format=yuv420p -f v4l2 /dev/video0
   ```

#### [ipwebcam-gst](https://github.com/agarciadom/ipwebcam-gst)

1. Setup [IP Webcam](https://play.google.com/store/apps/details?id=com.pas.webcam) on your phone

1. Setup `adb`

   ```sh
   $ adb devices
   ```

1. Start `ipwebcam-gst`

   ```sh
   # via wifi
   $ run-videochat -i <ip> -p <port> -v

   # e.g.
   $ run-videochat -i 127.0.0.1 -p 3333 -v

   # via adb
   $ run-videochat --adb-flags <device_id>
   ```

### [DroidCam](https://www.dev47apps.com/)

1. Setup DroidCam on your phone

1. Setup DroidCam on the host

   ```sh
   $ adb devices

   $ droidcam
   ```
