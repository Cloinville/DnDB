use csuciklo_dndb;

DROP VIEW IF EXISTS campaign_players;
CREATE VIEW campaign_players 
AS
SELECT player.player_id,
	   player.player_username,
	   `character`.char_id,
       `character`.char_name,
       adventuringparty.party_id,
       adventuringparty.party_name,
       campaign.campaign_id,
       campaign.campaign_name
FROM player JOIN `character` USING(player_id)
			JOIN adventuringparty USING(party_id)
            JOIN campaign USING(party_id);

DROP PROCEDURE IF EXISTS get_campaign_previews;
DELIMITER $$
CREATE PROCEDURE get_campaign_previews(IN in_username VARCHAR(32))
BEGIN
	SELECT campaign_id,
		   campaign_name, 
		   party_name
    FROM campaign_players
    WHERE player_username = in_username;
END $$
DELIMITER ;

# Create a view for each of the associated entities
DROP VIEW IF EXISTS character_abilities;
CREATE VIEW character_abilities
AS
SELECT *
FROM characterabilityscore JOIN ability USING(ability_id);

DROP VIEW IF EXISTS race_vulnerabilities;
CREATE VIEW race_vulnerabilities
AS
SELECT *
FROM vulnerability JOIN damagetype USING(damage_type_id);

DROP VIEW IF EXISTS race_resistances;
CREATE VIEW race_resistances
AS
SELECT *
FROM resistance JOIN damagetype USING(damage_type_id);

DROP VIEW IF EXISTS class_spells;
CREATE VIEW class_spells
AS
SELECT *
FROM classlearnablespell JOIN spell USING(spell_id);

DROP VIEW IF EXISTS spell_components;
CREATE VIEW spell_components
AS
SELECT *
FROM spellcomponent JOIN item USING(item_id);

DROP VIEW IF EXISTS monster_abilities;
CREATE VIEW monster_abilities
AS
SELECT *
FROM monsterabilityscore JOIN ability USING(ability_id);

DROP VIEW IF EXISTS race_ability_modifiers;
CREATE VIEW race_ability_modifiers
AS
SELECT *
FROM raceabilityscoremodifier JOIN ability USING(ability_id);

DROP TRIGGER IF EXISTS default_player_nickname;
DELIMITER $$
CREATE TRIGGER default_player_nickname
BEFORE
INSERT ON player
FOR EACH ROW
BEGIN
	IF NEW.player_nickname = ""
    THEN
		SET NEW.player_nickname = NEW.player_username;
	END IF;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_non_foreign_key_column_names_and_datatypes;
DELIMITER $$
CREATE PROCEDURE get_non_foreign_key_column_names_and_datatypes(IN entity VARCHAR(255))
BEGIN
	SELECT column_name, column_type
	FROM INFORMATION_SCHEMA.columns
	WHERE table_schema="csuciklo_dndb"
		  AND table_name = entity
		  AND column_key != "MUL";
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_foreign_key_column_names_and_referenced_table_names;
DELIMITER $$
CREATE PROCEDURE get_foreign_key_column_names_and_referenced_table_names(IN entity VARCHAR(255))
BEGIN
	SELECT COLUMN_NAME, REFERENCED_TABLE_NAME
	FROM INFORMATION_SCHEMA.key_column_usage
	WHERE table_schema="csuciklo_dndb" 
		  AND table_name = entity
          AND REFERENCED_TABLE_NAME IS NOT NULL;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_display_name;
DELIMITER $$
CREATE FUNCTION get_display_column_name(in_table_name VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE display_name VARCHAR(255) DEFAULT "";
    DECLARE display_name_prefix VARCHAR(255);
    DECLARE display_name_suffix VARCHAR(255) DEFAULT "_name";
    
    IF in_table_name = "player" THEN SET display_name_suffix = "_nickname";
    END IF;
    
    IF in_table_name = "character" THEN SET display_name_prefix = "char";
    ELSEIF in_table_name = "damagetype" THEN SET display_name_prefix = "damage_type";
    ELSEIF in_table_name = "schoolofmagic" THEN SET display_name_prefix = "magicschool";
    ELSE SET display_name_prefix = in_table_name;
    END IF;
    
    RETURN CONCAT(display_name_prefix, display_name_suffix);
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_table_name_from_primary_key_name;
DELIMITER $$
CREATE FUNCTION get_table_name_from_primary_key_name(primary_key_name VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
	DECLARE primary_key_prefix VARCHAR(255) DEFAULT "";
    SET primary_key_prefix = SUBSTRING_INDEX(primary_key_name, "_id", 1);
    
    IF primary_key_prefix = "damage_type" THEN SET primary_key_prefix = "damagetype";
    ELSEIF primary_key_prefix = "magicschool" THEN SET primary_key_prefix = "schoolofmagic";
    ELSEIF primary_key_prefix = "dm" THEN SET primary_key_prefix = "dungeonmaster";
    ELSEIF primary_key_prefix = "char" THEN SET primary_key_prefix = "character";
    ELSEIF primary_key_prefix = "encounter" THEN SET primary_key_prefix = "monsterencounter";
    END IF;
    
    RETURN primary_key_prefix;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS get_display_name_select_statement;
DELIMITER $$
CREATE FUNCTION get_display_name_select_statement(in_table_name VARCHAR(255))
RETURNS TEXT
DETERMINISTIC
BEGIN
	DECLARE select_statement TEXT DEFAULT "";
    IF in_table_name = "dungeonmaster" THEN 
		SET select_statement = "SELECT player_nickname FROM dungeonmaster JOIN player USING(player_id)";
    ELSEIF in_table_name = "monsterencounter" THEN SET select_statement = "SELECT monster_name FROM monster JOIN monsterencounter USING(monster_id)";
    ELSEIF in_table_name = "weapon" THEN SET select_statement = "SELECT item_name FROM weapon JOIN item USING(item_id)";
    ELSE SET select_statement = CONCAT("SELECT ", get_display_column_name(in_table_name), " FROM ", in_table_name);
    END IF;
    
    RETURN select_statement;
END $$
DELIMITER ;

# TODO: INSERT ON monster: IF NEW.monster_name IS NULL THEN SET NEW.monster_name = race_name of linked race
-- DROP VIEW IF EXISTS full_race_details;
-- CREATE VIEW full_race_details
-- AS
-- SELECT *
-- FROM race JOIN raceabilityscoremodifier USING(race_id)
-- 		  JOIN ability USING(ability_id)
--           JOIN raceknownlanguage USING(race_id)
--           JOIN `language` USING(language_id)
--           JOIN resistance USING(race_id)
--           JOIN vulnerability USING(race_id)
--           JOIN damagetype USING(damage_type_id);
          

-- DROP VIEW IF EXISTS full_character_details;
-- CREATE VIEW full_character_details
-- AS
-- SELECT *
-- FROM `character` JOIN characterabilityscore USING(char_id)
-- 				 JOIN ability USING(ability_id)
--                  JOIN race USING(race_id)
--                  JOIN 

-- # TODO: finish, using views that combine associated entity info
-- DROP VIEW IF EXISTS player_creations;
-- CREATE VIEW player_creations 
-- AS
-- SELECT *
-- FROM player JOIN `character` USING(player_id)
-- 			JOIN dungeonmaster USING(dm_id)
--             JOIN campaign USING(dm_id)
--             JOIN monster USING(dm_id)
--             JOIN monsterencounter USING(dm_id)
--             JOIN monsterparty USING(dm_id)
--             JOIN spell USING(dm_id)
--             JOIN race USING(dm_id);