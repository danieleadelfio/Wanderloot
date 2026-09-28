extends GdUnitTestSuite
## Numero di release (M13, #86): +1 a ogni export, cifre da 0 a 9 (1.0.9 -> 1.1.0, mai 1.0.10).


func test_next_increments_patch() -> void:
	assert_str(ReleaseVersion.next("1.0.6")).is_equal("1.0.7")


func test_patch_rolls_into_minor_at_ten() -> void:
	assert_str(ReleaseVersion.next("1.0.9")).is_equal("1.1.0")


func test_minor_rolls_into_major_at_ten() -> void:
	assert_str(ReleaseVersion.next("1.9.9")).is_equal("2.0.0")


func test_project_has_a_version() -> void:
	var parts := ReleaseVersion.current().split(".")
	assert_int(parts.size()).is_equal(3)
