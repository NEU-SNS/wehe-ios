# Adding a new language to the iOS app
This method allows us to export an [xliff](https://en.wikipedia.org/wiki/XLIFF) file, a standarized way of processing localizable data for localization for the translation team.
We are also able to edit this ourselves using this free [tool](https://itunes.apple.com/us/app/xlifftool/id1074282695?mt=12).

## 1. Enable support for new language in project
* In project settings: Project -> wehe -> Info -> Localiations
* select `+` and choose a desired language
* It should have both `InfoPlist.strings` and `Localizable.strings` selected.
* click `Finish`

## 2. Export xliff file
* Select the top most `wehe` in project navigator (the left panel), `wehe` should have a blue icon.
* In menu: Editor -> Export For Localizations...
* Inclide: `Existing Translations`
* Language: only check the newly added language
* click `Save`

## 3. Importing the xliff file
* Select the top most `wehe` in project navigator (the left panel), `wehe` should have a blue icon.
* In menu: Editor -> Import For Localizations...
* select the translated xliff file
* click `Import`