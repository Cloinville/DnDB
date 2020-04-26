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