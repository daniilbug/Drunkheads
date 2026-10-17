"""Shared 12×20 character poses for body, hair and clothing generators."""

FRAME_WIDTH = 12


def head_y(row: int, frame: int) -> int:
    # Walking changes support legs, not the vertical origin of the whole body.
    if row in (8, 9):
        return 1 + (0, -1, -1, 1)[frame]
    return 1


def walk_legs(row: int, frame: int) -> tuple:
    """Return two (x, y, far_side) legs, each 2×4 including the shoe.

    One sole always stays at y=18. Profile neutral/stride/neutral/stride poses
    exchange the legs horizontally; frame zero doubles as the standing pose.
    """
    if row in (2, 3):
        far, near = (
            ((4, 15), (6, 15)),
            ((3, 14), (7, 15)),
            ((6, 15), (4, 15)),
            ((7, 15), (3, 14)),
        )[frame]
        if row == 2:
            far = (FRAME_WIDTH - far[0] - 2, far[1])
            near = (FRAME_WIDTH - near[0] - 2, near[1])
        return ((*far, True), (*near, False))
    step = (0, -1, 0, 1)[frame]
    return ((3, 15 + min(step, 0), False), (7, 15 + min(-step, 0), False))


def walk_arms(row: int, frame: int, by: int) -> tuple[list, list]:
    """Ordered shoulder-to-hand paths; profiles return far arm, then near arm."""
    if row in (2, 3):
        far, near = (
            ([(5, 1), (5, 2), (5, 3), (5, 4)], [(6, 1), (6, 2), (6, 3), (6, 4)]),
            ([(6, 1), (7, 2), (8, 3), (9, 3)], [(6, 1), (5, 2), (4, 3), (3, 4)]),
            ([(5, 1), (5, 2), (5, 3), (5, 4)], [(6, 1), (6, 2), (6, 3), (6, 4)]),
            ([(5, 1), (4, 2), (3, 3), (2, 3)], [(6, 1), (7, 2), (8, 3), (9, 4)]),
        )[frame]
        if row == 2:
            far = [(FRAME_WIDTH - 1 - x, y) for x, y in far]
            near = [(FRAME_WIDTH - 1 - x, y) for x, y in near]
        return ([(x, by + y) for x, y in far], [(x, by + y) for x, y in near])
    left_step = -1 if frame == 3 else 0
    right_step = -1 if frame == 1 else 0
    return ([(2, by + y + left_step) for y in range(1, 5)],
            [(9, by + y + right_step) for y in range(1, 5)])


def arm_is_visible(row: int, arm: int, x: int, y: int, by: int) -> bool:
    # In profile the torso hides the far arm; it must not reappear on a shirt.
    return not (row in (2, 3) and arm == 0 and 3 <= x <= 8 and by <= y <= by + 4)
