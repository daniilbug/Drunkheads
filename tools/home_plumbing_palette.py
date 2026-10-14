"""Shared white and bright-gray colors for home plumbing sprites."""

WHITE = (255, 255, 255, 255)
PORCELAIN = (250, 250, 250, 255)
LIGHT_GRAY = (237, 239, 240, 255)
BRIGHT_GRAY = (222, 226, 228, 255)
GRAY = (199, 205, 208, 255)
MID_GRAY = (183, 190, 194, 255)
EDGE = (165, 173, 177, 255)


def with_alpha(color: tuple[int, int, int, int], alpha: int) -> tuple[int, int, int, int]:
    """Keep the shared color while making the shower glass see-through."""
    return (*color[:3], alpha)
