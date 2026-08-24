## 2026-08-24 - Cache DateFormatter for Loop Performance
**Learning:** Allocating DateFormatter instances inside a tight loop or map closure introduces massive overhead, leading to significant performance degradation.
**Action:** Cache the DateFormatter instance outside the loop to reuse it across iterations.
