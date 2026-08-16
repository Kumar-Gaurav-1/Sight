## 2024-06-03 - Cache standard formatters and encoders
**Learning:** Instantiating standard Swift encoders and decoders (like JSONEncoder and JSONDecoder) repeatedly can be inefficient, especially in high-frequency paths like IPC.
**Action:** Cache these instances as class properties instead of creating them on every method call.
