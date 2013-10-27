# Integration of CSS preprocessor in polymer.dart

## Introduction

styleproc_element is a dart library that enables the integration of any CSS preprocessor inside polymer.dart.

Candidate CSS preprocessors includes [Roole](http://roole.org), [Stylus](http://learnboost.github.io/stylus/) and [Less](http://lesscss.org/)

The main usage of this library is [roole_element](http://pub.dartlang.org/packages/roole_element) which integrates [Roole](http://roole.org) into polymer elements.  
However, this library is meant to be css-preprocessor agnistic. it can be used for any CSS preprocessor.


## Creating a CSS Preprocessor module

Create a mixin class that contains those methods.  
Example for a CSS preprocessor named `MyCSS`:

	class MyCSSPreprocessor {
	
	  String get styleElementName => "MyCSS"; // Will be the style
	                                         // element name
	
	  Future<String> compileStyleText(String txt) {
	    /* return a Future<String> that completes with the
	       css corresponding to txt compiled by MyCSS */
	  }
	
	}

Then create an element class:

	class MyCSSElement extends StyleProcessorElement with MyCSS {
	  MyCSSElement.created() : super.created() {}
	}

You're done !


## Using

Please refer to the [roole_element polymer element usage documenation](https://github.com/SalomonBrys/dart-roole-element#using-roole-inside-polymer-elements)
and simply translate from `Roole` & `RooleElement` to `MyCSS` & `MyCSSElement`.


## Troubleshooting

##### Can it work with SASS ?

No, SASS is written in ruby and C. It does not have a client side implementation.  
The javascript client attempt has not been updated for 2 years so that's not an option either.  
The only way to use SASS with polymer is to have a scss file that contains all your SASS style code, including your polymer elements style.  
You need to put `bool get applyAuthorStyles => true;` to all your polymer elements to disable shadowroot styling sandboxing.  
Then in your scss file, when you want to write a style that will apply to your element only you encapsulate it like this:

	my-element, [is=my-element] {
	  /* my-element style */
	}
