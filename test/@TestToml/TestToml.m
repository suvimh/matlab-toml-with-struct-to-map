classdef TestToml < matlab.unittest.TestCase

  methods (Test)

    function testComment(testCase)
      toml_str = sprintf('\n# this is a comment\n');
      testCase.assertEmpty(fieldnames(toml.parse(toml_str)), ...
        'Improper interpretation of a comment')
    end

    function testKeyValueForm(testCase)
      toml_str = 'key = #';
      testCase.assertError(@() toml.parse(toml_str), ...
        'toml:UnspecifiedValue', 'Did not fail for unspecified value')
    end

    function testEmptyBareKey(testCase)
      toml_str = sprintf('\nkey = "value"\n= "value2"');
      testCase.assertError(@() toml.parse(toml_str), ...
        'toml:EmptyBareKey', 'Did not fail for unspecified value')
    end

    function testAllowedCharsBareKey(testCase)
      toml_str1 = 'key_text = "value"';
      toml_str2 = 'key-text = "value"';
      toml_str3 = 'key123 = "value"';
      toml_str4 = 'KEY = "value"';
      toml_str5 = '1234 = "value"';
      testCase.verifyEqual(toml.parse(toml_str1), ...
        struct('key_text', 'value'), ...
        'Did not accept a bare key with an underscore.')
      testCase.verifyEqual(toml.parse(toml_str2), ...
        struct('key_text', 'value'), ...
        'Did not accept a bare key with a dash.')
      testCase.verifyEqual(toml.parse(toml_str3), ...
        struct('key123', 'value'), ...
        'Did not accept a bare key with digits.')
      testCase.verifyEqual(toml.parse(toml_str4), ...
        struct('KEY', 'value'), ...
        'Did not accept a bare key with uppercase ASCII.')
      testCase.verifyEqual(toml.parse(toml_str5), ...
        struct('f1234', 'value'), ...
        'Did not accept a bare key with only ASCII digits.')
    end

    function testQuotedKeys(testCase)
      toml_str1 = '"127.0.0.1" = "value"';
      toml_str2 = '"character encoding" = "value"';
      toml_str3 = '''key2'' = "value"';
      toml_str4 = '''quoted "value"'' = "value"';
      toml_str5 = '"" = "value"';
      testCase.verifyEqual(toml.parse(toml_str1), ...
        struct('f127_0_0_1', 'value'), ...
        'Did not handle quoted key with invalid format correctly.')
      testCase.verifyEqual(toml.parse(toml_str2), ...
        struct('character_encoding', 'value'), ...
        'Did not handle quoted key with space correctly.')
      testCase.verifyEqual(toml.parse(toml_str3), ...
        struct('key2', 'value'), ...
        'Did not handle single-quoted key correctly.')
      testCase.verifyEqual(toml.parse(toml_str4), ...
        struct('quoted_value', 'value'), ...
        'Did not handle nested quoting in key correctly.')
      testCase.verifyEqual(toml.parse(toml_str5), ...
        struct('f', 'value'), ...
        'Did not handle empty quoted key correctly.')
    end

    function testDottedKeys(testCase)
      toml_str1 = 'abc.def.ghi = "value"';
      toml_str2 = 'abc."def".ghi = "value"';
      toml_str3 = 'abc."quoted ''value''".ghi = "value"';
      testCase.verifyEqual(toml.parse(toml_str1), ...
        struct('abc', struct('def', struct('ghi', 'value'))), ...
        'Did not handle dotted key correctly.')
      testCase.verifyEqual(toml.parse(toml_str2), ...
        struct('abc', struct('def', struct('ghi', 'value'))), ...
        'Did not handle dotted and quoted key correctly.')
      testCase.verifyEqual(toml.parse(toml_str3), ...
        struct('abc', struct('quoted_value', struct('ghi', 'value'))), ...
        'Did not handle nested quoting in dotted key correctly.')
    end

    function testBasicString(testCase)
      toml_str1 = 'key = "value"';
      toml_str2 = sprintf('key = "line 1\nline 2"');
      toml_str3 = 'key = "disappearing A\b"';
      toml_str4 = 'key = "escaped \"quote\" marks"';
      toml_str5 = 'key = "inline \u0075nicode"';
      toml_str6 = 'key = "inline \U00000055nicode"';
      toml_str7 = 'key = "escaped\ttab"';
      testCase.verifyEqual(toml.parse(toml_str1), ...
        struct('key', 'value'), ...
        'Did not parse a basic string successfully.')
      testCase.verifyEqual(toml.parse(toml_str2), ...
        struct('key', sprintf('line 1\nline 2')), ...
        'Did not parse a basic string with a newline successfully.')
      testCase.verifyEqual(toml.parse(toml_str3), ...
        struct('key', sprintf('disappearing A\b')), ...
        'Did not parse a basic string with a backspace successfully.')
      testCase.verifyEqual(toml.parse(toml_str4), ...
        struct('key', 'escaped "quote" marks'), ...
        'Did not parse a basic string with escaped quotes successfully.')
      testCase.verifyEqual(toml.parse(toml_str5), ...
        struct('key', 'inline unicode'), ...
        'Did not parse a basic string with short Unicode successfully.')
      testCase.verifyEqual(toml.parse(toml_str6), ...
        struct('key', 'inline Unicode'), ...
        'Did not parse a basic string with long Unicode successfully.')
      testCase.verifyEqual(toml.parse(toml_str7), ...
        struct('key', sprintf('escaped\ttab')), ...
        'Did not parse a basic string with an escaped tab successfully.')
    end

    function testMultilineBasicString(testCase)
      toml_str1 = sprintf('key = """\nabcd"""');
      toml_str2 = sprintf('key = """line 1\n    line 2"""');
      toml_str3 = sprintf('key = """on the \\\n    same line"""');
      testCase.verifyEqual(toml.parse(toml_str1), ...
        struct('key', 'abcd'), ...
        'Did not parse a multiline basic string successfully.')
      testCase.verifyEqual(toml.parse(toml_str2), ...
        struct('key', sprintf('line 1\n    line 2')), ...
        'Did not parse a multiline basic string with indentation successfully.')
      testCase.verifyEqual(toml.parse(toml_str3), ...
        struct('key', sprintf('on the same line')), ...
        'Did not parse a multiline basic string with a LEB successfully.')
    end

    function testLiteralString(testCase)
      toml_str1 = 'key = ''C:\Users\example.txt''';
      toml_str2 = sprintf('key = ''''''\nNo leading newline here.''''''');
      testCase.verifyEqual(toml.parse(toml_str1), ...
       struct('key', 'C:\Users\example.txt'), ...
       'Did not parse a literal string with backslashes successfully.')
      testCase.verifyEqual(toml.parse(toml_str2), ...
       struct('key', 'No leading newline here.'), ...
       'Did not parse a literal string with a leading newline successfully.')
    end

    function testOffsetDateTime(testCase)
      % TOML version
      toml_str = { ...
          'odt = 1979-05-27T07:32:00Z' ...
        , 'odt = 1979-05-27T07:32:00-07:00' ...
        , 'odt = 1979-05-27T07:32:00.999999-07:00' ...
        , 'odt = 1979-05-27 07:32:00Z'...
                 };

      % matlab versions, respectively
      matl_obj = { ...
          datetime('1979-05-27 07:32:00', 'TimeZone', 'UTC') ...
        , datetime('1979-05-27 07:32:00-07:00', 'InputFormat', ...
                   'yyyy-MM-dd HH:mm:ssZ', 'TimeZone', 'UTC') ...
        , datetime('1979-05-27 07:32:00.999999-07:00', 'InputFormat', ...
                   'yyyy-MM-dd HH:mm:ss.SSSSSSSSSZ', 'TimeZone', 'UTC') ...
        , datetime('1979-05-27 07:32:00', 'TimeZone', 'UTC') ...
                 };

      % in structs for even easier reference
      matl_strct = cellfun(@(a) struct('odt', a), matl_obj);

      % check each one in turn
      for indx = 1:length(toml_str)
        testCase.verifyEqual(toml.parse(toml_str{indx}), matl_strct(indx), ...
        'Did not parse a fully qualified datetime successfully.')
      end
    end

    function testLocalDateTime(testCase)
      % TOML version
      toml_str = { ...
          'odt = 1979-05-27T07:32:00' ...
        , 'odt = 1979-05-27T07:32:00.999999' ...
        , 'odt = 1979-05-27 07:32:00'...
                 };

      % matlab versions, respectively
      matl_obj = { ...
          datetime('1979-05-27 07:32:00') ...
        , datetime('1979-05-27 07:32:00.999999', 'InputFormat', ...
                   'yyyy-MM-dd HH:mm:ss.SSSSSSSSS') ...
        , datetime('1979-05-27 07:32:00') ...
                 };

      % in structs for even easier reference
      matl_strct = cellfun(@(a) struct('odt', a), matl_obj);

      % check each one in turn
      for indx = 1:length(toml_str)
        testCase.verifyEqual(toml.parse(toml_str{indx}), matl_strct(indx), ...
        'Did not parse a fully qualified datetime successfully.')
      end
    end

    function testLocalDate(testCase)
      % TOML version
      toml_str = { ...
          'odt = 1979-05-27' ...
                 };

      % matlab versions, respectively
      matl_obj = { ...
          datetime('1979-05-27') ...
                 };

      % in structs for even easier reference
      matl_strct = cellfun(@(a) struct('odt', a), matl_obj);

      % check each one in turn
      for indx = 1:length(toml_str)
        testCase.verifyEqual(toml.parse(toml_str{indx}), matl_strct(indx), ...
        'Did not parse a fully qualified datetime successfully.')
      end
    end

    function testLocalTime(testCase)
      % TOML version
      toml_str = { ...
          'odt = 07:32:00' ...
        , 'odt = 07:32:00.999999' ...
                 };

      % matlab versions, respectively
      matl_obj = { ...
          datetime('07:32:00') ...
        , datetime('07:32:00.999999', 'InputFormat', ...
                   'HH:mm:ss.SSSSSSSSS') ...
                 };

      % in structs for even easier reference
      matl_strct = cellfun(@(a) struct('odt', a), matl_obj);

      % check each one in turn
      for indx = 1:length(toml_str)
        testCase.verifyEqual(toml.parse(toml_str{indx}), matl_strct(indx), ...
        'Did not parse a fully qualified datetime successfully.')
      end
    end

    function testArrays(testCase)
      % TOML version
      toml_str = { ...
          'key = [1, 2, 3]' ...
        , 'key = ["a", "b", "c"]' ...
        , 'key = [[1, 2], [''a'', "b"]]' ...
        , 'key = ["abcd", "comma, separated, values"]' ...
        , sprintf('key = [\n1, 2, 3\n]') ...
        , sprintf('key = [\n1,\n2,\n]') ...
                 };

      % matlab versions, respectively
      matl_obj(1).key = [1, 2, 3];
      matl_obj(2).key = {'a', 'b', 'c'};
      matl_obj(3).key = {[1, 2], {'a', 'b'}};
      matl_obj(4).key = {'abcd', 'comma, separated, values'};
      matl_obj(5).key = [1, 2, 3];
      matl_obj(6).key = [1, 2];

      % check each one in turn
      for indx = 1:length(toml_str)
        testCase.verifyEqual(toml.parse(toml_str{indx}), matl_obj(indx), ...
        'Did not parse an array successfully.')
      end
    end

    function testInlineTables(testCase)
      % TOML version
      toml_str = { ...
          'tbl = {}' ...
        , 'tbl = {first = "John", last = "Doe"}' ...
        , 'tbl = { x = 1, y = ["a", "b"] }' ...
        , 'tbl = { type.name = "cool type" }' ...
        , 'tbl = { thing = { wow = "very cool thing" } }' ...
                 };

      % matlab versions, respectively
      matl_obj = { ...
          struct() ...
        , struct('first', 'John', 'last', 'Doe') ...
        , struct('x', 1, 'y', {{'a', 'b'}}) ...
        , struct('type', struct('name', 'cool type')) ...
        , struct('thing', struct('wow', 'very cool thing')) ...
                 };

      % in structs for even easier reference
      matl_strct = cellfun(@(a) struct('tbl', a), matl_obj);

      % check each one in turn
      for indx = 1:length(toml_str)
        testCase.verifyEqual(toml.parse(toml_str{indx}), matl_strct(indx), ...
        'Did not parse an inline table successfully.')
      end
    end

  end

end