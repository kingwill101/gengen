---
title: 'Neat Tricks'
date: 2012-02-17T17:55:00.000-08:00
draft: false
aliases: [ "/2012/02/neopythonic-before-python.html" ]
---

For the longest while I have been thinking of documenting neat little snippets/patterns i find interesting, but you know the heart is willing but lazy takes over :D. Here's the first entry into what will hopefully be a continued documentation of my life of a developer.


Todays snippet is from my current "weekend" project. While this isn't new so to speak, it's a pattern i have never really thought of using. 


```php
public function file_path(string $path)
{
    $patterns = [
        resource_path('views/vendor/laropify/' . $path),
        #Check user-overridden theme files
        __DIR__ . '/../resources/views' . '/' . $path,
        # Check default package themes
        resource_path('views/laropify' . '/' . $path) # Check user-created themes in the application
    ];

    while (count($patterns)) {
        $pattern = array_shift($patterns);

        if (file_exists($pattern)) {
            return $pattern;
        }

        $userOverrideMatches = glob($pattern . "*.*");
        if (count($userOverrideMatches) > 0) {
            return $userOverrideMatches[0];
        }
    }

    logger()->error("Asset not found: $path", [
        "paths" => $patterns
    ]);

    throw new \Exception("$path not found");
}
```


