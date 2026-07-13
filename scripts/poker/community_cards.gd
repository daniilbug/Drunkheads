@tool
class_name CommunityCards
extends Node2D

@onready var _card1: Card = $Card1
@onready var _card2: Card = $Card2
@onready var _card3: Card = $Card3
@onready var _card4: Card = $Card4
@onready var _card5: Card = $Card5

func _ready() -> void:
	set_cards([])

func set_cards(cards: Array) -> void:
	var n       := cards.size()
	var all_cards: Array = [_card1, _card2, _card3, _card4, _card5]
	for i in range(1, 6):
		var card: Card = all_cards[i - 1]
		if i <= n:
			card.set_card(cards[i - 1], true)
		else:
			card.set_card(-1, false)
