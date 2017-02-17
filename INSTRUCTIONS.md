# config.sh
## Highly recommended

The config file specifies certain variables. It is actually a bash script, in order to provide maximum flexibility. The provided example includes all useable variables, as well as variables that may be used in these variables. It also automatically exports all of these for the parent script to use.

The following variables may be set:  
__name  
__tmp_dir  
__catalogue  
__smelt\_make\_mobile_bin  
__quick  

The following variables may be used:
__pid

# catalogue.xml
## Required

Note: catalogue.xml is the default name, but may be any name specified in the config.sh

At the most basic level, a catalogue must contain entries like so:  

```
	<ITEM>
		<NAME>./assets/minecraft/textures/blocks/dirt.png</NAME>
		<CONFIG>./conf/basic_block.sh</CONFIG>
		<SIZE></SIZE>
		<OPTIONS>dirt</OPTIONS>
		<KEEP>YES</KEEP>
		<DEPENDS></DEPENDS>
		<CLEANUP>./assets/minecraft/textures/blocks/dirt.svg</CLEANUP>
		<COMMON>Dirt</COMMON>
	</ITEM>
```

The fields are as follow:  

**ITEM** describes where to start and stop looking for each individual file to process.

**NAME** describes the output file name achieved. Formatted relative to the top folder of the resource pack.

**CONFIG** describes what file is used to process the file. More on this later. Also formatted relative to the top folder of the resource pack.

**SIZE** describes what size to process the file with. Rarely used. If blank, uses pack size. Mainly included for pack logo. Any positive integer will work.

**OPTIONS** describes any options to pass to the script. Placed after SIZE, as SIZE is passed as an option to all CONFIG scripts.

**KEEP** describes whether the produced file is intended for inclusion in the final resource pack. YES or NO answer. So if you are processing a working only file (an overlay, for instance), this is set to NO. Otherwise, YES.

**DEPENDS** describes any files this file **directly** relies on. For instance, if your script pulls in a file derived from wool, the colour file, nor wool overlay are required, only the directly used file. The render script extrapolates this information for use, so there is no need to do it ourselves. It **shouldn't** break things, but it's bad form, and not tested.

**CLEANUP** describes the source files to delete upon completion of the resource pack. Again, formatted relative to the top folder of the resource pack. For images composed entirely from pre-rendered images, this will be blank.

**COMMON** describes the common name of the texture. This is optional, and might be hard to fill in at times. Only useful on KEEP files.