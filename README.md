# fizz-iOS-Application-PDF_Fuzzer
An iOS application that fuzzes pdf files. 
Modified from https://github.com/nanidayo/fizz-iOS-Application-MP4_Fuzzer

#Help
Fizz - A shitty iOS Fuzzing Application<br><br>
Sleep time:<br>Tells the application how long you want to fuzz the file. <br>
10 seconds is the default and seems to work well...<br><br>
Seed:<br>The seed determines the possibility of the data changes.<br>
The lower the seed the higher the mutation (WIP).<br><br>
Just hit start and see if it crashes. If it does it should generate a crash report,<br>
if you're lucky a panic report (mediaserverd is the target). If not, oh well.<br>
The chances are slim... This is just a PoC~<br>
