# What is Goact?
 Goact is a GDScript derivative of Roblox's Roact, which itself is a derivative of Facebook's React library. This framework allows for a compositional, state based approach to game development that's useful for designing complex applications, traditionally well suited for UI/frontend development.
 
 This is nowhere near complete, mostly just a minimum viable product that still needs some work to get it adapted to the Godot ecosystem. Plus there are a lot of react/roact features that are still missing (like portals, fragments, hooks, etc.)
 
 See:
- Roact - https://github.com/Roblox/roact
- React - https://github.com/facebook/react

# Godot Version 4.x.x

 ## How to add to your project:
  - Copy the "goact" folder in "addons" into your project
  - Close and reopen if your editor is already open
  - Go to your project settings -> plugins and enable Goact
  - Might need to restart again, Godot plugins seemed a bit finicky for me.
  
 ## Examples
  - In this repo there's a project that uses some components I made as examples of what Goact looks like.
  - It essentially is a button that toggles an FPS counter, and some UX things like a selection indicator that tweens in/out when you hover on the button.
