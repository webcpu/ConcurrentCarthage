# Concurrent Carthage

**Concurrent** Carthage is a faster Carthage which utilizes multiple cores to build frameworks.

## Install
```   ruby main.rb  ``` 


## Speed Comparasion
Concurrent Carthage
```
carthage build --platform iOS --platform macOS  231.98s user 100.72s system 455% cpu 1:13.01 total
```

Original Carthage
```
carthage build --platform iOS --platform macOS  125.28s user 54.45s system 86% cpu 3:26.99 total
```

## Limitations
If your frameworks have too many nested dependencies, Concurrent Carthage can't speed it up very much.
