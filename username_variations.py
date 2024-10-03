#!/usr/bin/env python3

"""
Updated for Python 3
Generate complex username permutations similar to original Python 2 script.
"""

import sys
import getopt
from typing import List

# Program info
USERNAMER_VERSION = "1.0-rc3"
BUILD_DATE = "2023-11-11"

# Function to parse a single name
def parse_name(name: str):
    name_tokens = name.split()
    
    if len(name_tokens) < 2:
        print("Error: Name and at least one Surname must be supplied", file=sys.stderr)
        return
    
    # Split First Name and Surnames
    first_name = name_tokens[0]
    surnames = name_tokens[1:]
    
    results = []

    # Generate all permutations and abbreviations
    plugin_all_variations(first_name, surnames, results)

    # Final output
    for result in results:
        print(result)

# Plugin for generating complex username permutations like original script
def plugin_all_variations(first_name: str, surnames: List[str], result_list: List[str]):
    # Add normal permutations and concatenations
    surname_permutations = permutate_all(surnames)

    for perm in surname_permutations:
        result_list.append(first_name + ''.join(perm))
        result_list.append(''.join(perm) + first_name)
        result_list.append(first_name + '.' + ''.join(perm))
        result_list.append(''.join(perm) + '.' + first_name)
        result_list.append(first_name + '_' + ''.join(perm))
        result_list.append(''.join(perm) + '_' + first_name)

    # Single names and abbreviations
    result_list.append(first_name)
    result_list.extend(surnames)
    
    # Handle abbreviations and character reductions
    abbreviate_name(first_name, surnames, result_list)

# Abbreviation and reduction logic to mimic original
def abbreviate_name(first_name: str, surnames: List[str], result_list: List[str]):
    # Abbreviate first name and surnames in various combinations
    first_abbrev = abbreviate_string(first_name)
    
    for surname in surnames:
        surname_abbrev = abbreviate_string(surname)
        
        for abbr in first_abbrev:
            for sur_abbr in surname_abbrev:
                result_list.append(abbr + sur_abbr)
                result_list.append(sur_abbr + abbr)
                result_list.append(abbr + '_' + sur_abbr)
                result_list.append(sur_abbr + '_' + abbr)
                result_list.append(abbr + '.' + sur_abbr)
                result_list.append(sur_abbr + '.' + abbr)

    # Combine abbreviated first name with full surnames
    for abbr in first_abbrev:
        for surname in surnames:
            result_list.append(abbr + surname)
            result_list.append(surname + abbr)

# Utility to abbreviate a string by reducing characters progressively
def abbreviate_string(word: str) -> List[str]:
    return [word[:i] for i in range(1, len(word) + 1)]

# Utility function to generate all permutations of surnames
def permutate_all(tokens: List[str]):
    if len(tokens) <= 1:
        yield tokens
    else:
        for perm in permutate_all(tokens[1:]):
            for i in range(len(perm) + 1):
                yield perm[:i] + tokens[0:1] + perm[i:]

# Main function
def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "n:", ["name="])
        input_name = None

        for o, a in opts:
            if o in ("-n", "--name"):
                input_name = a

        if input_name is None:
            print("Error: Please specify a name", file=sys.stderr)
            sys.exit(2)

        if input_name:
            parse_name(input_name)

    except getopt.GetoptError as err:
        print(str(err), file=sys.stderr)
        sys.exit(2)

if __name__ == "__main__":
    main()
