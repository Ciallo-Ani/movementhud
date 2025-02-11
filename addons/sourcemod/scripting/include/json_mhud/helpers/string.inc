/**
 * vim: set ts=4 :
 * =============================================================================
 * sm-json
 * A pure SourcePawn JSON encoder/decoder.
 * https://github.com/clugg/sm-json
 *
 * sm-json (C)2022 James Dickens. (clug)
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 */

#if defined _json_helpers_string_included
 #endinput
#endif
#define _json_helpers_string_included

#include <json_mhud/helpers/unicode>

/**
 * Mapping characters to their escaped form.
 */
char JSON_STRING_NORMAL[][]  = {
    "\\",   "\"",   "/",   "\b",  "\f",  "\n",  "\r",  "\t"
};
char JSON_STRING_ESCAPED[][] = {
    "\\\\", "\\\"", "\\/", "\\b", "\\f", "\\n", "\\r", "\\t"
};

/**
 * Escapes a string in-place in a buffer.
 *
 * @param buffer    String buffer.
 * @param max_size  Maximum size of string buffer.
 */
stock void json_escape_string(char[] buffer, int max_size)
{
    for (int i = 0; i < sizeof(JSON_STRING_NORMAL); i += 1) {
        ReplaceString(
            buffer,
            max_size,
            JSON_STRING_NORMAL[i],
            JSON_STRING_ESCAPED[i]
        );
    }

    int length = strlen(buffer) + 1;
    for (int pos = 0; pos < length && pos < max_size; pos += 1) {
        if (buffer[pos] < 0x80) {
            // skip standard ascii values
            continue;
        }

        // consume the ascii bytes of the next utf8 character
        int ascii_size;
        int utf8 = json_ascii_to_utf8(buffer[pos], length - pos, ascii_size);
        if (ascii_size <= 0) {
            continue;
        }

        // convert the utf8 value to escaped format
        char escaped[7];
        FormatEx(escaped, sizeof(escaped), "\\u%04x", utf8);

        // duplicate the consumed byte array
        ascii_size += 1;
        char[] ascii = new char[ascii_size];
        for (int i = 0; i < ascii_size; i += 1) {
            ascii[i] = buffer[pos + i];
        }
        ascii[ascii_size - 1] = '\0';

        // replace bytes with the escaped value
        int replacements = ReplaceString(buffer, max_size, ascii, escaped);

        // calculate new string length based on replacements made
        length -= replacements * ascii_size - 1;
        length += replacements * sizeof(escaped) - 1;

        // skip to the last of the bytes we just replaced
        pos += sizeof(escaped) - 2;
    }
}

/**
 * Unescapes a string in-place in a buffer.
 *
 * @param buffer    String buffer.
 * @param max_size  Maximum size of string buffer.
 */
stock void json_unescape_string(char[] buffer, int max_size)
{
    int length = strlen(buffer) + 1;
    int continuous_backslashes = 0;
    for (int pos = 0; pos < length && pos < max_size; pos += 1) {
        if (buffer[pos] == '\\') {
            continuous_backslashes += 1;
        } else {
            if (continuous_backslashes % 2 != 0 && buffer[pos] == 'u') {
                // consume the entire escape starting at backslash
                pos -= 1;
                char escaped[7];
                for (int i = 0; i < 6; i += 1) {
                    escaped[i] = buffer[pos + i];
                }
                escaped[sizeof(escaped) - 1] = '\0';

                // convert the hex to decimal
                int utf8 = StringToInt(escaped[2], 16);

                // convert the utf8 to ascii
                int ascii_size = json_utf8_to_ascii_size(utf8) + 1;
                char[] ascii = new char[ascii_size];
                int written = json_utf8_to_ascii(utf8, ascii, ascii_size);

                // replace the escaped value with ascii bytes
                int replacements = ReplaceString(
                    buffer,
                    max_size,
                    escaped,
                    ascii,
                    false
                );

                // calculate new string length based on replacements made
                length -= replacements * sizeof(escaped) - 1;
                length += replacements * written;

                // skip to the last of the bytes we just replaced
                pos += written - 1;
            }

            continuous_backslashes = 0;
        }
    }

    for (int i = 0; i < sizeof(JSON_STRING_NORMAL); i += 1) {
        ReplaceString(
            buffer,
            max_size,
            JSON_STRING_ESCAPED[i],
            JSON_STRING_NORMAL[i]
        );
    }
}

/**
 * Checks whether the provided character is a valid hexadecimal character.
 *
 * @param c     Character to check.
 * @return      True if c is a hexadecimal character, false otherwise.
 */
stock bool json_char_is_hex(int c)
{
    return (
        (c >= '0' && c <= '9')
        || (c >= 'a' && c <= 'f')
        || (c >= 'A' && c <= 'F')
    );
}

/**
 * Calculates the maximum buffer length required to
 * store the JSON cell representation of a string.
 *
 * @param length    The length of the string.
 * @return          Maximum buffer length.
 */
stock int json_cell_string_size(const char[] input)
{
    int size = 3; // for outside quotes + NULL terminator

    bool foundEscapeTarget = false;
    int length = strlen(input);
    for (int pos = 0; pos < length; pos += 1) {
        foundEscapeTarget = false;
        for (int i = 0; i < sizeof(JSON_STRING_NORMAL); i += 1) {
            if (input[pos] == JSON_STRING_NORMAL[i][0]) {
                size += 2;
                foundEscapeTarget = true;
                break;
            }
        }

        if (foundEscapeTarget) {
            continue;
        }

        if (input[pos] < 0x80) {
            size += 1;
            continue;
        }

        // consume the ascii bytes of the next utf8 character
        int ascii_size;
        json_ascii_to_utf8(input[pos], length - pos, ascii_size);
        if (ascii_size <= 0) {
            continue;
        }

        pos += ascii_size - 1;
        size += 6; // for unicode escape is \uXXXX
    }

    return size;
}

/**
 * Generates the JSON cell representation of a string.
 *
 * @param input     Value to generate output for.
 * @param output    String buffer to store output.
 * @param max_size  Maximum size of string buffer.
 */
stock void json_cell_string(const char[] input, char[] output, int max_size)
{
    // add input string to output, offset for start/end quotes
    strcopy(output[1], max_size - 2, input);

    // escape the output
    json_escape_string(output[1], max_size - 2);

    // surround output with quotations
    output[0] = '"';
    StrCat(output, max_size, "\"");
}
