
require "selftest_utils"

class CMDTEST_unicode < Cmdtest::Testcase

  include SelftestUtils

  def test_unicode

    create_CMDTEST_foo [
      "cmd 'create_unicode_file.rb' do",
      "    created_files 'tmp-ΑΒΓ-αβγ-א-Њ-åäöÅÄÖ.txt'",
      "end",
    ]

    cmd_cmdtest do
      stdout_equal [
        "### create_unicode_file.rb",
      ]
    end

  end


end
