### [IP Webcam](https://play.google.com/store/apps/details?id=com.pas.webcam)

#### Obs

1. Setup `IP Webcam` on your phone

1. Forward the output of `IP Webcam` to the host

   ```
   $ adb devices

   $ adb forward tcp:<host_port> tcp:<device_port>

   # e.g.
   $ adb forward tcp:3333 tcp:8080
   ```

1. Setup `Obs`

   Create a `Media Source` with input value: `http://<ip>:<port>/videofeed`, e.g. `http://localhost:3333/videofeed`

1. TODO: Start virtual camera instructions

#### [ipwebcam-gst](https://github.com/agarciadom/ipwebcam-gst)

1. Setup [IP Webcam](https://play.google.com/store/apps/details?id=com.pas.webcam) on your phone

1. Setup `adb`

   ```
   $ adb devices
   ```

1. Start ipwebcam-gst

   ```
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

   ```
   $ adb devices

   $ droidcam
   ```
