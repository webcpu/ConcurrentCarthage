# frozen_string_literal: true

class TestApp < Minitest::Test
  def setup
    @app = App.new
  end

  def test_check
    assert_equal true, @app.check
  end

  def test_clone
    assert_equal true, @app.clone
  end

  def test_build
    assert_equal true, @app.build
  end
end
