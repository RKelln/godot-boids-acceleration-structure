# Boids in Godot with Acceleration Structure

![Screenshot of godot boids](https://raw.githubusercontent.com/RKelln/godot-boids-acceleration-structure/jackson/godot_boids_screenshot.png)

This work is based off Stephen Young's [[kyrick/godot-boids-acceleration-structure]](https://github.com/kyrick/godot-boids-acceleration-structure).


Stephen implemented an 'acceleration structure' to optimize the nearest neighbour lookups. All boid locations are stored in a 2D which represents the space. The boids query the structure to get cells based on the facing of the boids. The boids then filter that list based on their view range. This way the boid isn't looping over the entire list of boids. It's only concerned with it's immediate surroundings. 

The physics engine is slowed down to 20 Hz to increase the number of boids while keeping the frame rate above 30. You can adjust the physics engine Hz in Project Settings->Physics->Common->Physics FPS. Additionally boids are split into 4 groups and only update their 'boidyness' at 5 fps. There are few other tricks that help with the flocking behaviour that I'd love to remove on a faster machine or with better flight physics, but this is doing what I need it to for now. (PRs welcome).

For more information on boids see [Craig Reynolds Boids](https://en.wikipedia.org/wiki/Boids). A more detailed breakdown of [Boids with pseudocode can be found here](http://www.kfish.org/boids/pseudocode.html).


# Running the Demo

Click F5 to run the default screen. Then click anywhere on the screen to issue a waypoint for the boids. The boids will continue to chase mouse clicks.

Controls: 

	`Esc`: Display help
	`Space`: Pause

	`G`: Toggle GUI
	`B`: Toggle background
	`M`: Toggle midi/music 
	`P`: Toggle paint mode
	`T`: Toggle trails
	`A`: Zoom in
	`Z`: Zoom out

	`1`-`7`: 'Play' color notes

	`D` : toggle debug info (red indicates speed, blue indicates emergency avoidance behaviour)


# Adjusting the simulation

You can control the parameters of the simulation during playback using the GUI at the bottom. You can set the initial values for these in the `GUI` scene, for each `SliderControl`.

The Crow scene script variables:
* Cohesion - boids will head towards the largest center of mass of nearby boids
* Alignment - boids will try to align themselves in the same direction as nearby boids 
* Separation - boids will try to keep their distance from other boids
* Sight distance - how far a boid will look ahead and to the side for cohesion, alignment, and separation
* Avoid distance - the distance at which a boid will try to avoid another boid
* Max Speed - the maximum speed of the boid


# Credits

This was forked from Stephen Young's [kyrick/godot-boids-acceleration-structure](https://github.com/kyrick/godot-boids-acceleration-structure), many thanks to them!

This project uses the [FarmPuzzleAnimals](https://comigo.itch.io/farm-puzzle-animals) pack created by [CoMiGo](https://comigo.itch.io/).
