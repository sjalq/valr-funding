
# Fusion Editor Implementation Prompt

Implement a type-aware editor tab in the Admin page that allows direct manipulation of the application's backend model. The implementation should:

1. Add a new "Fusion" tab to the Admin page navigation accessible via the `/admin/fusion` route
2. Create a `viewFusionTab` function that renders the editor with dark background styling
3. Integrate the `Fusion.Editor.value` component with these configurations:
   - Use the application's type dictionary from `Fusion.Generated.TypeDict.typeDict`
   - Target the BackendModel type specifically
   - Configure message handlers:
     - `Admin_FusionPatch` for handling model edits
     - `Admin_FusionQuery` for handling queries
   - Pass in the current editor state from `model.fusionState`
4. Ensure proper type definitions are added to the application's Types.elm file:
   - Add `Admin_FusionPatch` and `Admin_FusionQuery` to the message types
   - Add `fusionState` to the relevant model
5. Style the editor within a container with appropriate headings and spacing

The editor should provide a type-aware interface for viewing and modifying the application's backend model structure at runtime.
