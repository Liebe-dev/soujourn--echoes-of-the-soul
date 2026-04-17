extends Node

@onready var dialogue_ui = $DialogueUI

func _ready():

	var data = [

	{
		"name":"Hero",
		"text":"Where... am I?",
		"sprite":{"character":"hero","expression":"neutral","position":"center"}
	},

	{
		"name":"Girl",
		"text":"Oh! You're finally awake.",
		"sprite":{"character":"girl","expression":"smile","position":"right"}
	},

	{
		"name":"Hero",
		"text":"Who are you?",
		"sprite":{"character":"hero","expression":"surprised","position":"center"}
	},

	{
		"name":"Girl",
		"text":"My name is Aria. I found you unconscious in the forest.",
		"sprite":{"character":"girl","expression":"normal","position":"right"}
	},

	{
		"name":"Hero",
		"text":"A forest...? I don't remember anything...",
		"sprite":{"character":"hero","expression":"sad","position":"center"}
	},

	{
		"name":"Aria",
		"text":"Maybe you lost your memory.",
		"sprite":{"character":"girl","expression":"thinking","position":"right"}
	},

	{
		"name":"Hero",
		"text":"What should I do now?"
	},

	{
		"name":"Aria",
		"text":"Well... what do you want to do?",
		"choices":[

			{
				"text":"Ask about the forest",
				"next":8
			},

			{
				"text":"Ask about Aria",
				"next":12
			},

			{
				"text":"Leave immediately",
				"next":16
			}

		]
	},

	# ===== branch 1 =====

	{
		"name":"Hero",
		"text":"Where exactly are we?"
	},

	{
		"name":"Aria",
		"text":"This is the Whispering Forest. It's dangerous at night."
	},

	{
		"name":"Hero",
		"text":"Dangerous how?"
	},

	{
		"name":"Aria",
		"text":"Monsters wander here after sunset..."
	},

	# ===== branch 2 =====

	{
		"name":"Hero",
		"text":"Tell me about yourself."
	},

	{
		"name":"Aria",
		"text":"I'm just a traveler. I explore ruins and forests."
	},

	{
		"name":"Hero",
		"text":"Sounds dangerous."
	},

	{
		"name":"Aria",
		"text":"Maybe... but it's exciting."
	},

	# ===== branch 3 =====

	{
		"name":"Hero",
		"text":"I should leave now."
	},

	{
		"name":"Aria",
		"text":"Wait! It's not safe yet!"
	},

	{
		"name":"Hero",
		"text":"I'll take my chances."
	},

	{
		"name":"Narrator",
		"text":"The wind howls through the trees..."
	},

	{
		"name":"Narrator",
		"text":"Something moves in the shadows..."
	},

	{
		"name":"Aria",
		"text":"Did you hear that?"
	},

	{
		"name":"Hero",
		"text":"Yeah..."
	},

	{
		"name":"Narrator",
		"text":"To be continued..."
	}

	]

	dialogue_ui.start_dialogue(data)
