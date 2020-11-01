# defmodule TravelMenu do
#   def handle({:init, target_id}, entity_id) do
#     %MenuSelect{
#       text: "Where would you like to go?",
#       options: [
#         buya: "Go to Buya",
#         nagnag: "Go to Nagnag",
#         blah: "Go to Blah"
#       ],
#       next: {:confirm_town, target_id}
#     }
#   end

#   def handle({:confirm_town, target_id}, entity_id) do
#     case selection do
#       0 ->
#         %MenuText{
#           text: "Buya is a beautiful city! Enjoy!",
#           next: {:confirm_travel, target_id}
#         }
#     end
#   end

#   def handle({:confirm_travel, target_id}, entity_id) do
#     %MenuSelect{
#       text: "You wish to travel there?",
#       options: [
#         yes: "Yes!",
#         no: "No"
#       ],
#       next: TravelMenu.step_select() / 1
#     }
#   end

#   def step_select(:yes) do
#     Game.World.warp_entity(300, 30, 30)
#   end
# end
