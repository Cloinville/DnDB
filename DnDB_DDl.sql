USE csuciklo_dndb;
-- # Saved list of all table drops for cleaning while finalizing structure
-- # TODO: 1. Remove this once no longer needed, BEFORE final submission!
-- #	   2. Add "password" field to player in CREATE TABLE statement
--
-- DROP TABLE levelallocation;
-- DROP TABLE classlearnablespell;
-- DROP TABLE raceabilityscoremodifier;
-- DROP TABLE learnedspell;
-- DROP TABLE class;
-- DROP TABLE classlevelnewspellscount;
-- DROP TABLE raceknownlanguage;
-- DROP TABLE characterlearnedlanguage;
-- DROP TABLE characterinventoryitem;
-- DROP TABLE monsterlootitem;
-- DROP TABLE monsterencounter;
-- DROP TABLE monsterparty;
-- DROP TABLE characterabilityscore;
-- DROP TABLE monsterabilityscore;
-- DROP TABLE spell;
-- DROP TABLE schoolofmagic;
-- DROP TABLE `language`;
-- DROP TABLE weapon;
-- DROP TABLE item;
-- DROP TABLE `character`;
-- DROP TABLE monster;
-- DROP TABLE race;
-- DROP TABLE skill;
-- DROP TABLE ability;
-- DROP TABLE campaign;
-- DROP TABLE adventuringparty;
-- DROP TABLE dungeonmaster;
-- DROP TABLE player;

# Table creation
CREATE TABLE player(
	player_id INT(10) PRIMARY KEY AUTO_INCREMENT,
    player_username VARCHAR(32) UNIQUE NOT NULL,
--     player_nickname VARCHAR(128) NOT NULL,
	player_nickname VARCHAR(16) NOT NULL,
    player_password VARCHAR(32) NOT NULL
)ENGINE=InnoDB;

CREATE TABLE dungeonmaster(
	dm_id INT(10) PRIMARY KEY AUTO_INCREMENT,
    player_id INT(10) UNIQUE NOT NULL
)ENGINE=InnoDB;

CREATE TABLE campaign(
	campaign_id INT(10) PRIMARY KEY AUTO_INCREMENT,
    campaign_name VARCHAR(128) DEFAULT NULL,
    campaign_plot_description TEXT DEFAULT NULL,
    campaign_setting_description TEXT DEFAULT NULL,
    campaign_is_active BOOLEAN DEFAULT FALSE NOT NULL,
    dm_id INT(10) NOT NULL,
    campaign_party_name VARCHAR(128) DEFAULT NULL
)ENGINE=InnoDB;

CREATE TABLE ability(
	ability_id TINYINT PRIMARY KEY AUTO_INCREMENT,
    ability_name VARCHAR(12) DEFAULT NULL,
    ability_description TEXT DEFAULT NULL
)ENGINE=InnoDB;

CREATE TABLE skill(
	skill_id TINYINT PRIMARY KEY AUTO_INCREMENT,
    skill_name VARCHAR(64) NOT NULL,
    skill_description TEXT DEFAULT NULL,
    skill_is_trained_only BOOLEAN DEFAULT FALSE,
    ability_id TINYINT DEFAULT NULL
)ENGINE=InnoDB;

CREATE TABLE monster(
	monster_id INT(10) PRIMARY KEY AUTO_INCREMENT,
    monster_name VARCHAR(128) DEFAULT NULL,
    monster_ac TINYINT NOT NULL DEFAULT 10,
    monster_challenge_rating FLOAT DEFAULT NULL,
    monster_description TEXT DEFAULT NULL,
    monster_base_hp SMALLINT DEFAULT 0,
    monster_type ENUM(
						"abberation", "beast", "celestial", "construct", "dragon",
                        "elemental", "fey", "fiend",
                        "fiend (shapechanger)", "giant", "humanoid", "monstrosity",
                        "ooze", "plant", "swarm of tiny beasts", "undead", "other"
					 ) NOT NULL DEFAULT "other",
    dm_id INT(10)
)ENGINE=InnoDB;

CREATE TABLE race(
	race_id SMALLINT PRIMARY KEY AUTO_INCREMENT,
--     race_is_playable BOOLEAN DEFAULT FALSE,
    race_name VARCHAR(128) DEFAULT NULL,
    race_description TEXT DEFAULT NULL,
    race_speed SMALLINT DEFAULT NULL,
    race_size VARCHAR(24) DEFAULT NULL,
    dm_id INT(10) DEFAULT NULL
)ENGINE=InnoDB;

CREATE TABLE `character`(
	char_id INT(10) PRIMARY KEY AUTO_INCREMENT,
    char_name VARCHAR(255) DEFAULT NULL,
    char_gender VARCHAR(32) DEFAULT NULL,
    char_backstory TEXT DEFAULT NULL,
    char_age SMALLINT NOT NULL DEFAULT 0,
    char_height VARCHAR(10) DEFAULT NULL,
    char_notes TEXT DEFAULT NULL,
    char_public_class ENUM(
								"barbarian", "bard", "cleric", "druid", "fighter",
								"monk", "paladin", "ranger", "rogue", "sorcerer",
                                "warlock", "wizard", "multiclass", "classless"
						   ) NOT NULL DEFAULT "classless",
    char_base_hp SMALLINT NOT NULL DEFAULT 0,
    char_hp_remaining SMALLINT NOT NULL DEFAULT 0,
    char_platinum INT NOT NULL DEFAULT 0,
    char_gold INT NOT NULL DEFAULT 0,
    char_silver INT NOT NULL DEFAULT 0,
    char_copper INT NOT NULL DEFAULT 0,
    race_id SMALLINT NOT NULL,
    # party_id INT(10) DEFAULT NULL,
    player_id INT(10) NOT NULL,
	char_overall_level TINYINT NOT NULL DEFAULT 0
)ENGINE=InnoDB;

CREATE TABLE item(
	item_id INT(10) PRIMARY KEY AUTO_INCREMENT, # changed [first table where NOTED change]
    item_name VARCHAR(128) DEFAULT NULL,
    item_description TEXT DEFAULT NULL,
    item_rarity ENUM(
						"common", "uncommon", "rare", "very rare", "legendary"
					) NOT NULL DEFAULT "common",
    item_type ENUM(
					"armor", "weapon", "potion", "ring", "rod", "scroll", "staff",
					"wand", "wondrous item", "equipment", "shiled", "ammunition",
                    "ordinary"
				  ) NOT NULL DEFAULT "ordinary",
    item_price VARCHAR(128) DEFAULT NULL,
    item_requires_attunement BOOLEAN DEFAULT FALSE,
    dm_id INT(10) DEFAULT NULL
)ENGINE=InnoDB;

CREATE TABLE weapon(
	weapon_id SMALLINT PRIMARY KEY AUTO_INCREMENT,
    weapon_num_dice_to_roll VARCHAR(4) NOT NULL,
    weapon_damage_modifier TINYINT NOT NULL DEFAULT 0,
    weapon_range SMALLINT DEFAULT NULL,
    damage_type VARCHAR(32) NOT NULL,
    item_id INT(10) UNIQUE NOT NULL
)ENGINE=InnoDB;

CREATE TABLE `language`(
	language_id TINYINT PRIMARY KEY AUTO_INCREMENT,
    language_name VARCHAR(64) NOT NULL,
    language_description TEXT DEFAULT NULL
)ENGINE=InnoDB;

CREATE TABLE schoolofmagic(
	magicschool_id TINYINT PRIMARY KEY AUTO_INCREMENT,
    magicschool_name VARCHAR(64) NOT NULL,
    magicschool_description TEXT DEFAULT NULL
)ENGINE=InnoDB;

CREATE TABLE spell(
	spell_id SMALLINT PRIMARY KEY AUTO_INCREMENT,
    spell_name VARCHAR(255) NOT NULL,
    spell_description TEXT DEFAULT NULL,
    spell_min_level TINYINT NOT NULL DEFAULT 0,
    spell_range VARCHAR(128) NOT NULL DEFAULT "no range",
    spell_casting_time VARCHAR(64) DEFAULT NULL,
    spell_duration VARCHAR(64) DEFAULT NULL,
    spell_is_concentration BOOLEAN NOT NULL DEFAULT FALSE,
    spell_material TEXT DEFAULT NULL,
    magicschool_id TINYINT DEFAULT NULL,
    dm_id INT(10) DEFAULT NULL
)ENGINE=InnoDB;

CREATE TABLE raceknownlanguage(
	race_id SMALLINT,
    language_id TINYINT,
    PRIMARY KEY(race_id, language_id)
)ENGINE=InnoDB;

CREATE TABLE characterlearnedlanguage(
	char_id INT(10),
    language_id TINYINT,
    PRIMARY KEY(char_id, language_id)
)ENGINE=InnoDB;

CREATE TABLE characterinventoryitem(
	char_id INT(10),
    item_id INT(10),
    characterinventoryitem_counter SMALLINT NOT NULL DEFAULT 0,
    PRIMARY KEY(char_id, item_id, characterinventoryitem_counter)
)ENGINE=InnoDB;

CREATE TABLE monsterlootitem(
	encounter_id INT(11),
    item_id INT(10),
    monsterlootitem_counter SMALLINT NOT NULL DEFAULT 0,
    PRIMARY KEY(encounter_id, item_id, monsterlootitem_counter)	
)ENGINE=InnoDB;

CREATE TABLE monsterencounter(
	encounter_id INT(11) PRIMARY KEY AUTO_INCREMENT,
    monster_id INT(10) NOT NULL,
    monsterparty_id INT(11) NOT NULL,
    encounter_hp_remaining SMALLINT NOT NULL DEFAULT 0
)ENGINE=InnoDB;

CREATE TABLE monsterparty(
	monsterparty_id INT(11) PRIMARY KEY AUTO_INCREMENT,
    monsterparty_location TEXT DEFAULT NULL,
    dm_id INT(10) DEFAULT NULL,
    campaign_id INT(10) NOT NULL
)ENGINE=InnoDB;

CREATE TABLE characterabilityscore(
	char_id INT(10),
    ability_id TINYINT,
    charabilityscore_value TINYINT NOT NULL CHECK(charabilityscore_value >= 0),
    PRIMARY KEY(char_id, ability_id)
)ENGINE=InnoDB;

CREATE TABLE monsterabilityscore(
	monster_id INT(10),
    ability_id TINYINT,
    monsterabilityscore_value TINYINT NOT NULL CHECK(monsterabilityscore_value >= 0),
    PRIMARY KEY(monster_id, ability_id)
)ENGINE=InnoDB;

CREATE TABLE raceabilityscoremodifier(
	race_id SMALLINT,
    ability_id TINYINT,
    racemodifier_value TINYINT NOT NULL CHECK(racemodifier_value >= 0),
    PRIMARY KEY(race_id, ability_id)
)ENGINE=InnoDB;

CREATE TABLE learnedspell(
	spell_id SMALLINT NOT NULL,
    char_id INT(10) NOT NULL,
    PRIMARY KEY(spell_id, char_id)
)ENGINE=InnoDB;

CREATE TABLE class(
	class_id SMALLINT PRIMARY KEY AUTO_INCREMENT,
    class_name VARCHAR(24) NOT NULL,
    class_description TEXT DEFAULT NULL,
    class_hit_die ENUM("d4", "d6", "d8", "d10", "d12") NOT NULL DEFAULT "d4",
    class_role ENUM("tank", "support", "glass cannon") NOT NULL DEFAULT "support"
)ENGINE=InnoDB;

CREATE TABLE classlevelnewspellscount(
	class_id SMALLINT,
    newspellscount_class_level TINYINT NOT NULL DEFAULT 1 CHECK(newspellscount_class_level >= 1),
    newspellscount_cantrips TINYINT NOT NULL DEFAULT 0,
    newspellscount_spells TINYINT NOT NULL DEFAULT 0,
    newspellscount_spell_slots_level_1 TINYINT NOT NULL DEFAULT 0,
    newspellscount_spell_slots_level_2 TINYINT NOT NULL DEFAULT 0,
    newspellscount_spell_slots_level_3 TINYINT NOT NULL DEFAULT 0,
    newspellscount_spell_slots_level_4 TINYINT NOT NULL DEFAULT 0,
    newspellscount_spell_slots_level_5 TINYINT NOT NULL DEFAULT 0,
    newspellscount_spell_slots_level_6 TINYINT NOT NULL DEFAULT 0,
    newspellscount_spell_slots_level_7 TINYINT NOT NULL DEFAULT 0,
    newspellscount_spell_slots_level_8 TINYINT NOT NULL DEFAULT 0,
    newspellscount_spell_slots_level_9 TINYINT NOT NULL DEFAULT 0,
    PRIMARY KEY(class_id, newspellscount_class_level)
)ENGINE=InnoDB;

CREATE TABLE classlearnablespell(
	spell_id SMALLINT,
    class_id SMALLINT,
    cls_required_class_level TINYINT NOT NULL DEFAULT 1 CHECK(cls_required_class_level >= 1),
    PRIMARY KEY(spell_id, class_id)
)ENGINE=InnoDB;

CREATE TABLE levelallocation(
    char_id INT(10) NOT NULL,
	class_id SMALLINT NOT NULL,
    levelallocation_level TINYINT NOT NULL DEFAULT 1 CHECK(levelallocation_level >= 1),
    PRIMARY KEY(char_id, class_id)
)ENGINE=InnoDB;

CREATE TABLE partymember(
	campaign_id INT(10) NOT NULL,
    player_id INT(10) NOT NULL,
    char_id INT(10) UNIQUE DEFAULT NULL,
    PRIMARY KEY(campaign_id, player_id)
)ENGINE=InnoDB;

# Add foreign key constraints
ALTER TABLE dungeonmaster ADD CONSTRAINT `dm_fk_player_id` FOREIGN KEY(player_id) REFERENCES player(player_id);
ALTER TABLE campaign ADD CONSTRAINT `campaign_fk_dm_id` FOREIGN KEY(dm_id) REFERENCES dungeonmaster(dm_id);
# ALTER TABLE campaign ADD CONSTRAINT `campaign_fk_party_id` FOREIGN KEY(party_id) REFERENCES adventuringparty(party_id);
ALTER TABLE skill ADD CONSTRAINT `skill_fk_ability_id` FOREIGN KEY(ability_id) REFERENCES ability(ability_id);
ALTER TABLE monster ADD CONSTRAINT `monster_fk_dm_id` FOREIGN KEY(dm_id) REFERENCES dungeonmaster(dm_id);
ALTER TABLE race ADD CONSTRAINT `race_fk_dm_id` FOREIGN KEY(dm_id) REFERENCES dungeonmaster(dm_id);
ALTER TABLE `character` ADD CONSTRAINT `character_fk_race_id` FOREIGN KEY(race_id) REFERENCES race(race_id);
# ALTER TABLE `character` ADD CONSTRAINT `character_fk_party_id` FOREIGN KEY(party_id) REFERENCES adventuringparty(party_id);
ALTER TABLE `character` ADD CONSTRAINT `character_fk_player_id` FOREIGN KEY(player_id) REFERENCES player(player_id);
ALTER TABLE item ADD CONSTRAINT `item_fk_dm_id` FOREIGN KEY(dm_id) REFERENCES dungeonmaster(dm_id);
ALTER TABLE weapon ADD CONSTRAINT `weapon_fk_item_id` FOREIGN KEY(item_id) REFERENCES item(item_id);
ALTER TABLE spell ADD CONSTRAINT `spell_fk_magicschool_id` FOREIGN KEY(magicschool_id) REFERENCES schoolofmagic(magicschool_id);
ALTER TABLE spell ADD CONSTRAINT `spell_fk_dm_id` FOREIGN KEY(dm_id) REFERENCES dungeonmaster(dm_id);
ALTER TABLE raceknownlanguage ADD CONSTRAINT `raceknownlanguage_fk_race_id` FOREIGN KEY(race_id) REFERENCES race(race_id);
ALTER TABLE raceknownlanguage ADD CONSTRAINT `raceknownlanguage_fk_language_id` FOREIGN KEY(language_id) REFERENCES `language`(language_id);
ALTER TABLE characterlearnedlanguage ADD CONSTRAINT `characterlearnedlanguage_fk_char_id` FOREIGN KEY(char_id) REFERENCES `character`(char_id);
ALTER TABLE characterlearnedlanguage ADD CONSTRAINT `characterlearnedlanguage_fk_language_id` FOREIGN KEY(language_id) REFERENCES `language`(language_id);
ALTER TABLE characterinventoryitem ADD CONSTRAINT `characterinventoryitem_fk_char_id` FOREIGN KEY(char_id) REFERENCES `character`(char_id);
ALTER TABLE characterinventoryitem ADD CONSTRAINT `characterinventoryitem_fk_item_id` FOREIGN KEY(item_id) REFERENCES item(item_id);
ALTER TABLE monsterlootitem ADD CONSTRAINT `monsterlootitem_fk_encounter_id` FOREIGN KEY(encounter_id) REFERENCES monsterencounter(encounter_id);
ALTER TABLE monsterlootitem ADD CONSTRAINT `monsterlootitem_fk_item_id` FOREIGN KEY(item_id) REFERENCES item(item_id);
ALTER TABLE monsterencounter ADD CONSTRAINT `monsterencounter_fk_monster_id` FOREIGN KEY(monster_id) REFERENCES monster(monster_id);
ALTER TABLE monsterencounter ADD CONSTRAINT `monsterencounter_fk_monsterparty_id` FOREIGN KEY(monsterparty_id) REFERENCES monsterparty(monsterparty_id);
ALTER TABLE monsterparty ADD CONSTRAINT `monsterparty_fk_dm_id` FOREIGN KEY(dm_id) REFERENCES dungeonmaster(dm_id);
ALTER TABLE monsterparty ADD CONSTRAINT `monsterparty_fk_campaign_id` FOREIGN KEY(campaign_id) REFERENCES campaign(campaign_id);
ALTER TABLE characterabilityscore ADD CONSTRAINT `characterabilityscore_fk_char_id` FOREIGN KEY(char_id) REFERENCES `character`(char_id);
ALTER TABLE characterabilityscore ADD CONSTRAINT `characterabilityscore_fk_ability_id` FOREIGN KEY(ability_id) REFERENCES ability(ability_id);
ALTER TABLE monsterabilityscore ADD CONSTRAINT `monsterabilityscore_fk_monster_id` FOREIGN KEY(monster_id) REFERENCES monster(monster_id);
ALTER TABLE monsterabilityscore ADD CONSTRAINT `monsterabilityscore_fk_ability_id` FOREIGN KEY(ability_id) REFERENCES ability(ability_id);
ALTER TABLE raceabilityscoremodifier ADD CONSTRAINT `raceabilityscoremodifier_fk_race_id` FOREIGN KEY(race_id) REFERENCES race(race_id);
ALTER TABLE raceabilityscoremodifier ADD CONSTRAINT `raceabilityscoremodifier_fk_ability_id` FOREIGN KEY(ability_id) REFERENCES ability(ability_id);
ALTER TABLE learnedspell ADD CONSTRAINT `learnedspell_fk_char_id` FOREIGN KEY(char_id) REFERENCES `character`(char_id);
ALTER TABLE learnedspell ADD CONSTRAINT `learnedspell_fk_spell_id` FOREIGN KEY(spell_id) REFERENCES spell(spell_id);
ALTER TABLE classlevelnewspellscount ADD CONSTRAINT `clnsc_fk_class_id` FOREIGN KEY(class_id) REFERENCES class(class_id);
ALTER TABLE levelallocation ADD CONSTRAINT `levelallocation_fk_char_id` FOREIGN KEY(char_id) REFERENCES `character`(char_id);
ALTER TABLE levelallocation ADD CONSTRAINT `levelallocation_fk_class_id` FOREIGN KEY(class_id) REFERENCES class(class_id);
ALTER TABLE classlearnablespell ADD CONSTRAINT `cls_fk_class_id` FOREIGN KEY(class_id) REFERENCES class(class_id);
ALTER TABLE classlearnablespell ADD CONSTRAINT `cls_fk_spell_id` FOREIGN KEY(spell_id) REFERENCES spell(spell_id);
ALTER TABLE partymember ADD CONSTRAINT `partymember_fk_campaign_id` FOREIGN KEY(campaign_id) REFERENCES campaign(campaign_id);
ALTER TABLE partymember ADD CONSTRAINT `partymember_fk_player_id` FOREIGN KEY(player_id) REFERENCES player(player_id);
ALTER TABLE partymember ADD CONSTRAINT `partymember_fk_char_id` FOREIGN KEY(char_id) REFERENCES `character`(char_id);
