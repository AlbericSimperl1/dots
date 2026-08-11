#!/bin/bash
if [ -z "$@" ]; then
  echo "Typ een som... (bijv. 5 * 10)"
else
  # Gebruik python3 om de som veilig en snel uit te rekenen
  result=$(python3 -c "print(eval(\"$@\"))" 2>/dev/null)
  if [ -n "$result" ]; then
    echo "Resultaat: $result"
    echo "Kopieer"
  else
    echo "Ongeldige invoer"
  fi
fi
