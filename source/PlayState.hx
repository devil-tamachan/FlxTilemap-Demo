package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.FlxObject;
import Std;
import openfl.Assets;
import flixel.util.FlxStringUtil;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

/**
 * A FlxState which can be used for the actual gameplay.
 */
class PlayState extends FlxState
{	
	// Some static constants for the size of the tilemap tiles
	static private inline var TILE_WIDTH:UInt = 16;
	static private inline var TILE_HEIGHT:UInt = 16;
	
	// The FlxTilemap we're using
	private var collisionMap:FlxTilemap;
	
	// Box to show the user where they're placing stuff
	private var highlightBox:FlxSprite;
		
	// Player modified from "Mode" demo
	private var player:FlxSprite;
	
	// Some interface buttons and text
	private var autoAltBtn:FlxButton;
	private var resetBtn:FlxButton;
	private var quitBtn:FlxButton;
	private var helperTxt:FlxText;
	
	/**
	 * Function that is called up when to state is created to set it up. 
	 */
	override public function create():Void
	{
		super.create();
		//FlxG.framerate = 50;
		//FlxG.flashFramerate = 50;
			
		// Creates a new tilemap with no arguments
		collisionMap = new FlxTilemap();
			
		/*
		 * FlxTilemaps are created using strings of comma seperated values (csv)
		 * This string ends up looking something like this:
		 *
		 * 0,0,0,0,0,0,0,0,0,0,
		 * 0,0,0,0,0,0,0,0,0,0,
		 * 0,0,0,0,0,0,1,1,1,0,
		 * 0,0,1,1,1,0,0,0,0,0,
		 * ...
		 *
		 * Each '0' stands for an empty tile, and each '1' stands for
		 * a solid tile
		 *
		 * When using the auto map generation, the '1's are converted into the corresponding frame
		 * in the tileset.
		 */
			
		// Initializes the map using the generated string, the tile images, and the tile size
		collisionMap.loadMap(Assets.getText(AssetPaths.default_auto__txt), AssetPaths.auto_tiles__png, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.AUTO);
		add(collisionMap);
			
		highlightBox = new FlxSprite(0, 0);
		highlightBox.makeGraphic(TILE_WIDTH, TILE_HEIGHT, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRect(highlightBox, 0, 0, TILE_WIDTH - 1, TILE_HEIGHT - 1, FlxColor.TRANSPARENT, { thickness: 1, color: FlxColor.RED });
		add(highlightBox);
			
		setupPlayer();
			
		// When switching between modes here, the map is reloaded with it's own data, so the positions of tiles are kept the same
		// Notice that different tilesets are used when the auto mode is switched
		autoAltBtn = new FlxButton(4, FlxG.height - 24, "AUTO", function():Void
		{
			switch(collisionMap.auto)
			{
				case FlxTilemap.AUTO:
					collisionMap.loadMap(FlxStringUtil.arrayToCSV(collisionMap.getData(true), collisionMap.widthInTiles),
						AssetPaths.alt_tiles__png, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.ALT);
					autoAltBtn.label.text = "ALT";
					//break;
					
				case FlxTilemap.ALT:
					collisionMap.loadMap(FlxStringUtil.arrayToCSV(collisionMap.getData(true), collisionMap.widthInTiles),
						AssetPaths.empty_tiles__png, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.OFF);
					autoAltBtn.label.text = "OFF";
					//break;
					
				case FlxTilemap.OFF:
					collisionMap.loadMap(FlxStringUtil.arrayToCSV(collisionMap.getData(true), collisionMap.widthInTiles),
						AssetPaths.auto_tiles__png, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.AUTO);
					autoAltBtn.label.text = "AUTO";
					//break;
			}
		});
		add(autoAltBtn);
			
		resetBtn = new FlxButton(8 + autoAltBtn.width, FlxG.height - 24, "Reset", function():Void
		{
			switch(collisionMap.auto)
			{
				case FlxTilemap.AUTO:
					collisionMap.loadMap(Assets.getText(AssetPaths.default_auto__txt), AssetPaths.auto_tiles__png, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.AUTO);
					player.x = 64;
					player.y = 220;
					//break;
					
				case FlxTilemap.ALT:
					collisionMap.loadMap(Assets.getText(AssetPaths.default_alt__txt), AssetPaths.alt_tiles__png, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.ALT);
					player.x = 64;
					player.y = 128;
					//break;
					
				case FlxTilemap.OFF:
					collisionMap.loadMap(Assets.getText(AssetPaths.default_empty__txt), AssetPaths.empty_tiles__png, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.OFF);
					player.x = 64;
					player.y = 64;
					//break;
			}
		});
		add(resetBtn);
		
		quitBtn = new FlxButton(FlxG.width - resetBtn.width - 4, FlxG.height - 24, "終了Quit",
			function():Void { FlxG.camera.fade(0xff000000, 0.22, false, function():Void { FlxG.switchState(new MenuState()); } ); } );
		add(quitBtn);
		
		helperTxt = new FlxText(12 + autoAltBtn.width*2, FlxG.height - 30, 150, "Click to place tiles\nShift-Click to remove tiles\nArrow keys to move");
		add(helperTxt);
	}
	
	/**
	 * Function that is called when this state is destroyed - you might want to 
	 * consider setting all objects this state uses to null to help garbage collection.
	 */
	override public function destroy():Void
	{
		super.destroy();
	}

	/**
	 * Function that is called once every frame.
	 */
	override public function update():Void
	{
		// Tilemaps can be collided just like any other FlxObject, and flixel
		// automatically collides each individual tile with the object.
		FlxG.collide(player, collisionMap);
		
		highlightBox.x = Math.floor(FlxG.mouse.x / TILE_WIDTH) * TILE_WIDTH;
		highlightBox.y = Math.floor(FlxG.mouse.y / TILE_HEIGHT) * TILE_HEIGHT;
		
		if (FlxG.mouse.pressed)
		{
			// FlxTilemaps can be manually edited at runtime as well.
			// Setting a tile to 0 removes it, and setting it to anything else will place a tile.
			// If auto map is on, the map will automatically update all surrounding tiles.
			collisionMap.setTile(Std.int(FlxG.mouse.x / TILE_WIDTH), Std.int(FlxG.mouse.y / TILE_HEIGHT), FlxG.keys.pressed.SHIFT?0:1);
		}
		
		updatePlayer();
		super.update();
	}
	
	public override function draw():Void
	{
		super.draw();
		highlightBox.draw();
	}
	
	private function setupPlayer():Void
	{
		player = new FlxSprite(64, 220);
		player.loadGraphic(AssetPaths.spaceman__png, true, 16);
		player.setFacingFlip(FlxObject.LEFT, true, false);
		player.setFacingFlip(FlxObject.RIGHT, false, false);
		
		//bounding box tweaks
		player.width = 14;
		player.height = 14;
		player.offset.x = 1;
		player.offset.y = 1;
		
		//basic player physics
		player.drag.x = 640;
		player.acceleration.y = 420;
		player.maxVelocity.x = 80;
		player.maxVelocity.y = 200;
		
		//animations
		player.animation.add("idle", [0]);
		player.animation.add("run", [1, 2, 3, 0], 12);
		player.animation.add("jump", [4]);
		
		add(player);
	}
	
	private function updatePlayer():Void
	{
		wrap(player);
		
		//MOVEMENT
		player.acceleration.x = 0;
		if(FlxG.keys.pressed.LEFT)
		{
			player.facing = FlxObject.LEFT;
			player.acceleration.x -= player.drag.x;
		}
		else if(FlxG.keys.pressed.RIGHT)
		{
			player.facing = FlxObject.RIGHT;
			player.acceleration.x += player.drag.x;
		}
		if(FlxG.keys.justPressed.UP && player.velocity.y == 0)
		{
			player.y -= 1;
			player.velocity.y = -200;
		}
		
		//ANIMATION
		if(player.velocity.y != 0)
		{
			player.animation.play("jump");
		}
		else if(player.velocity.x == 0)
		{
			player.animation.play("idle");
		}
		else
		{
			player.animation.play("run");
		}
	}
	
	private function wrap(obj:FlxObject):Void
	{
		obj.x = (obj.x + obj.width / 2 + FlxG.width) % FlxG.width - obj.width / 2;
		obj.y = (obj.y + obj.height / 2) % FlxG.height - obj.height / 2;
	}
}