# JSON-Optimizer

This Ruby script takes an `Animation.json` file from _Adobe Animate's_ "Texture Atlas" export and optimizes it in the following ways:

* By removing all white-space. _Adobe Animate's_ output is "prettified", which makes it easy to read, but blows up the file size enormously.
* By removing `DecomposedMatrix` elements. This data is redundant and not required by the extension.
* By combining identical, empty frames via their `duration` property. This can take up a lot of space on empty layers.
* Optionally, by zipping the file. When combined with the [ZipLoader](https://wiki.starling-framework.org/extensions/zipped-assets), the _AnimAssetManager_ can load those zip-files directly at run-time.

### Installation

You need to have [Ruby](https://www.ruby-lang.org) and [RubyGems](https://rubygems.org) installed on your system. You also need the `rubyzip` gem; like any RubyGem, it can be installed like this:

    gem install rubyzip

### Usage

When that's done, you can call the script like this:

    cd tools/optimize_json
    ruby optimize_json.rb path/to/Animation.json

This will optimize `Animation.json` in place; you can also leave the input file unchanged and let the optimized version be stored under a different path or name:

    ruby optimize_json.rb path/to/Animation.json path/to/out.json

You can get a list of options by running the script without parameters:

```
ruby optimize_json.rb
Usage: optimize_json.rb [options] input_file [output_file]

Common options:
    -z, --zip                        Zip output file
    -p, --prettify                   Prettify output file
    -h, --help                       Show this message
```

For example, to zip the output file, use the following command:

    ruby optimize_json.rb --zip Animation.json

This will add the file `Animation.json.zip` to the same folder.

### Results

As for the results the tool can achieve, here's what happens with the "Ninja Girl" animation file.

- Original output from Adobe: 4.1 MB (zipped: 99kB)
- Optimized with "optimize_json": 476 kB (zipped: 32 kB)
