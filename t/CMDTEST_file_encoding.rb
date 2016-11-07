
require "selftest_utils"

class CMDTEST_file_encoding < Cmdtest::Testcase

  include SelftestUtils

  #----------------------------------------
  # 'file_encoding' detects equal file encoding + bom

  def test_file_encoding_UTF8_CORRECT
    create_CMDTEST_foo [
      "file_open('foo', 'w') {|f| f.write \"\\uFEFFabc-αβγ-Г-א-åäö\\n\" }",
      "",
      "cmd 'true.rb' do",
      "    file_encoding 'foo', 'UTF-8'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  def test_file_encoding_UTF8_INCORRECT
    create_CMDTEST_foo [
      "file_open('foo', 'wb') {|f| f.write \"\\xffabc-αβγ-Г-א-åäö\\n\" }",
      "",
      "cmd 'true.rb' do",
      "    file_encoding 'foo', 'UTF-8'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: file not in encoding: foo, UTF-8",
      ]
      exit_nonzero
    end
  end

  def test_file_encoding_UTF8_CORRECT_BOM_true_CORRECT
    create_CMDTEST_foo [
      "file_open('foo', 'w') {|f| f.write \"\\uFEFFabc-αβγ-Г-א-åäö\\n\" }",
      "",
      "cmd 'true.rb' do",
      "    file_encoding 'foo', 'UTF-8', bom: true",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  def test_file_encoding_UTF8_CORRECT_BOM_false_INCORRECT
    create_CMDTEST_foo [
      "file_open('foo', 'w') {|f| f.write \"\\uFEFFabc-αβγ-Г-א-åäö\\n\" }",
      "",
      "cmd 'true.rb' do",
      "    file_encoding 'foo', 'UTF-8', bom: false",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: file has unexpected BOM: foo",
      ]
      exit_nonzero
    end
  end

  def test_file_encoding_UTF8_CORRECT_BOM_false_CORRECT
    create_CMDTEST_foo [
      "file_open('foo', 'w') {|f| f.write \"abc-αβγ-Г-א-åäö\\n\" }",
      "",
      "cmd 'true.rb' do",
      "    file_encoding 'foo', 'UTF-8', bom: false",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
      ]
    end
  end

  def test_file_encoding_UTF8_CORRECT_BOM_true_INCORRECT
    create_CMDTEST_foo [
      "file_open('foo', 'w') {|f| f.write \"abc-αβγ-Г-א-åäö\\n\" }",
      "",
      "cmd 'true.rb' do",
      "    file_encoding 'foo', 'UTF-8', bom: true",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### true.rb",
        "--- ERROR: file hasn't expected BOM: foo",
      ]
      exit_nonzero
    end
  end


end
