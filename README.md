# Structured Volume Sampling

This project explores Structured Volume Sampling; a
[method](https://github.com/huwb/volsample) introduced by
[Bowles](http://www.huwbowles.com/) and Zimmermann for minimizing aliasing when
ray marching unbounded volumetrics in real-time. The algorithm functions by
sampling the volume from implicit planes located at fixed world-space
positions. This is in contrast to the more traditional approach where the
sampling planes move with the camera, leading to severe aliasing.

![Structured Volume Sampling](http://i.imgur.com/kDZvORx.png)

