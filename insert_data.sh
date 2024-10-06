#! /bin/bash

# Check if the first argument is "test"
if [[ $1 == "test" ]]
then
  # Use test database
  DB_QUERY="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  # Use production database
  DB_QUERY="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Clear existing data from teams and games tables
echo $($DB_QUERY "TRUNCATE teams, games")
echo -e "Waiting for data import..."

# Initialize a counter for the number of processed lines
line_counter=0

# Read data from games.csv
while IFS="," read -r year round winner opponent winner_goals opponent_goals
do
  ((line_counter++)) # Increment the line counter

  # Skip the header row
  if [[ $year != "year" ]]
  then
    # Fetch team IDs or insert teams if they do not exist
    winner_id=$($DB_QUERY "SELECT team_id FROM teams WHERE name='$winner'")
    opponent_id=$($DB_QUERY "SELECT team_id FROM teams WHERE name='$opponent'")
    
    # Insert winner if not found
    if [[ -z $winner_id ]]
    then
      $DB_QUERY "INSERT INTO teams(name) VALUES('$winner')"
      winner_id=$($DB_QUERY "SELECT team_id FROM teams WHERE name='$winner'")
    fi
    
    # Insert opponent if not found
    if [[ -z $opponent_id ]]
    then
      $DB_QUERY "INSERT INTO teams(name) VALUES('$opponent')"
      opponent_id=$($DB_QUERY "SELECT team_id FROM teams WHERE name='$opponent'")
    fi
    
    # Insert game data
    $DB_QUERY "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES($year, '$round', $winner_id, $opponent_id, $winner_goals, $opponent_goals)"
  fi
  
  echo "Processed line: $line_counter"
done < games.csv

echo -e "Data import completed successfully."
