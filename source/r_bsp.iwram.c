/* Emacs style mode select   -*- C++ -*-
 *-----------------------------------------------------------------------------
 *
 *
 *  PrBoom: a Doom port merged with LxDoom and LSDLDoom
 *  based on BOOM, a modified and improved DOOM engine
 *  Copyright (C) 1999 by
 *  id Software, Chi Hoang, Lee Killough, Jim Flynn, Rand Phares, Ty Halderman
 *  Copyright (C) 1999-2000 by
 *  Jess Haas, Nicolas Kalkhof, Colin Phipps, Florian Schulze
 *  Copyright 2005, 2006 by
 *  Florian Schulze, Colin Phipps, Neil Stevens, Andrey Budko
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation; either version 2
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 *  02111-1307, USA.
 *
 * DESCRIPTION:
 *      BSP traversal, handling of LineSegs for rendering.
 *
 *-----------------------------------------------------------------------------*/

#include "doomstat.h"
#include "m_bbox.h"
#include "r_main.h"
#include "r_segs.h"
#include "r_plane.h"
#include "r_things.h"
#include "r_bsp.h" // cph - sanity checking
#include "v_video.h"
#include "lprintf.h"

#include "global_data.h"

//
// R_ClearDrawSegs
//

void R_ClearDrawSegs(void)
{
  _g->ds_p = _g->drawsegs;
}

// CPhipps -
// R_ClipWallSegment
//
// Replaces the old R_Clip*WallSegment functions. It draws bits of walls in those
// columns which aren't solid, and updates the solidcol[] array appropriately

static void R_ClipWallSegment(int first, int last, boolean solid)
{
    byte *p;
    while (first < last)
    {
        if (_g->solidcol[first])
        {
            if (!(p = memchr(_g->solidcol+first, 0, last-first)))
                return; // All solid

            first = p - _g->solidcol;
        }
        else
        {
            int to;
            if (!(p = memchr(_g->solidcol+first, 1, last-first)))
                to = last;
            else
                to = p - _g->solidcol;

            R_StoreWallRange(first, to-1);

            if (solid)
            {
                memset(_g->solidcol+first,1,to-first);
            }

            first = to;
        }
    }
}

//
// R_ClearClipSegs
//

void R_ClearClipSegs (void)
{
  memset(_g->solidcol, 0, SCREENWIDTH);
}

// killough 1/18/98 -- This function is used to fix the automap bug which
// showed lines behind closed doors simply because the door had a dropoff.
//
// cph - converted to R_RecalcLineFlags. This recalculates all the flags for
// a line, including closure and texture tiling.

static void R_RecalcLineFlags(void)
{
  _g->linedef->r_validcount = _g->gametic;

  /* First decide if the line is closed, normal, or invisible */
  if (!(_g->linedef->flags & ML_TWOSIDED)
      || _g->backsector->ceilingheight <= _g->frontsector->floorheight
      || _g->backsector->floorheight >= _g->frontsector->ceilingheight
      || (
    // if door is closed because back is shut:
    _g->backsector->ceilingheight <= _g->backsector->floorheight

    // preserve a kind of transparent door/lift special effect:
    && (_g->backsector->ceilingheight >= _g->frontsector->ceilingheight ||
        _g->curline->sidedef->toptexture)

    && (_g->backsector->floorheight <= _g->frontsector->floorheight ||
        _g->curline->sidedef->bottomtexture)

    // properly render skies (consider door "open" if both ceilings are sky):
    && (_g->backsector->ceilingpic !=_g->skyflatnum ||
        _g->frontsector->ceilingpic!=_g->skyflatnum)
    )
      )
    _g->linedef->r_flags = RF_CLOSED;
  else
  {
      // Reject empty lines used for triggers
      //  and special events.
      // Identical floor and ceiling on both sides,
      // identical light levels on both sides,
      // and no middle texture.
      // CPhipps - recode for speed, not certain if this is portable though
      if (_g->backsector->ceilingheight != _g->frontsector->ceilingheight
              || _g->backsector->floorheight != _g->frontsector->floorheight
              || _g->curline->sidedef->midtexture
              || _g->backsector->ceilingpic != _g->frontsector->ceilingpic
              || _g->backsector->floorpic != _g->frontsector->floorpic
              || _g->backsector->lightlevel != _g->frontsector->lightlevel)
      {
          _g->linedef->r_flags = 0; return;
      } else
          _g->linedef->r_flags = RF_IGNORE;
  }

  /* cph - I'm too lazy to try and work with offsets in this */
  if (_g->curline->sidedef->rowoffset) return;

  /* Now decide on texture tiling */
  if (_g->linedef->flags & ML_TWOSIDED) {
    int c;

    /* Does top texture need tiling */
    if ((c = _g->frontsector->ceilingheight - _g->backsector->ceilingheight) > 0 &&
   (_g->textureheight[_g->texturetranslation[_g->curline->sidedef->toptexture]] > c))
      _g->linedef->r_flags |= RF_TOP_TILE;

    /* Does bottom texture need tiling */
    if ((c = _g->frontsector->floorheight - _g->backsector->floorheight) > 0 &&
   (_g->textureheight[_g->texturetranslation[_g->curline->sidedef->bottomtexture]] > c))
      _g->linedef->r_flags |= RF_BOT_TILE;
  } else {
    int c;
    /* Does middle texture need tiling */
    if ((c = _g->frontsector->ceilingheight - _g->frontsector->floorheight) > 0 &&
   (_g->textureheight[_g->texturetranslation[_g->curline->sidedef->midtexture]] > c))
      _g->linedef->r_flags |= RF_MID_TILE;
  }
}

//
// R_AddLine
// Clips the given segment
// and adds any visible pieces to the line list.
//

static void R_AddLine (seg_t *line)
{
  int      x1;
  int      x2;
  angle_t  angle1;
  angle_t  angle2;
  angle_t  span;
  angle_t  tspan;

  _g->curline = line;

  angle1 = R_PointToAngle (line->v1->x, line->v1->y);
  angle2 = R_PointToAngle (line->v2->x, line->v2->y);

  // Clip to view edges.
  span = angle1 - angle2;

  // Back side, i.e. backface culling
  if (span >= ANG180)
    return;

  // Global angle needed by segcalc.
  _g->rw_angle1 = angle1;
  angle1 -= _g->viewangle;
  angle2 -= _g->viewangle;

  tspan = angle1 + clipangle;
  if (tspan > 2*clipangle)
    {
      tspan -= 2*clipangle;

      // Totally off the left edge?
      if (tspan >= span)
        return;

      angle1 = clipangle;
    }

  tspan = clipangle - angle2;
  if (tspan > 2*clipangle)
    {
      tspan -= 2*clipangle;

      // Totally off the left edge?
      if (tspan >= span)
        return;
      angle2 = 0-clipangle;
    }

  // The seg is in the view range,
  // but not necessarily visible.

  angle1 = (angle1+ANG90)>>ANGLETOFINESHIFT;
  angle2 = (angle2+ANG90)>>ANGLETOFINESHIFT;

  // killough 1/31/98: Here is where "slime trails" can SOMETIMES occur:
  x1 = viewangletox[angle1];
  x2 = viewangletox[angle2];

  // Does not cross a pixel?
  if (x1 >= x2)       // killough 1/31/98 -- change == to >= for robustness
    return;

  _g->backsector = line->backsector;

  /* cph - roll up linedef properties in flags */
  if ((_g->linedef = _g->curline->linedef)->r_validcount != _g->gametic)
    R_RecalcLineFlags();

  if (_g->linedef->r_flags & RF_IGNORE)
  {
    return;
  }
  else
    R_ClipWallSegment (x1, x2, _g->linedef->r_flags & RF_CLOSED);
}

//
// R_CheckBBox
// Checks BSP node/subtree bounding box.
// Returns true
//  if some part of the bbox might be visible.
//

static const int checkcoord[12][4] = // killough -- static const
{
  {3,0,2,1},
  {3,0,2,0},
  {3,1,2,0},
  {0},
  {2,0,2,1},
  {0,0,0,0},
  {3,1,3,0},
  {0},
  {2,0,3,1},
  {2,1,3,1},
  {2,1,3,0}
};

// killough 1/28/98: static // CPhipps - const parameter, reformatted
static boolean R_CheckBBox(const short *bspcoord)
{
  angle_t angle1, angle2;

  {
    int        boxpos;
    const int* check;

    // Find the corners of the box
    // that define the edges from current viewpoint.
    boxpos = (_g->viewx <= ((fixed_t)bspcoord[BOXLEFT]<<FRACBITS) ? 0 : _g->viewx < ((fixed_t)bspcoord[BOXRIGHT]<<FRACBITS) ? 1 : 2) +
      (_g->viewy >= ((fixed_t)bspcoord[BOXTOP]<<FRACBITS) ? 0 : _g->viewy > ((fixed_t)bspcoord[BOXBOTTOM]<<FRACBITS) ? 4 : 8);

    if (boxpos == 5)
      return true;

    check = checkcoord[boxpos];
    angle1 = R_PointToAngle (((fixed_t)bspcoord[check[0]]<<FRACBITS), ((fixed_t)bspcoord[check[1]]<<FRACBITS)) - _g->viewangle;
    angle2 = R_PointToAngle (((fixed_t)bspcoord[check[2]]<<FRACBITS), ((fixed_t)bspcoord[check[3]]<<FRACBITS)) - _g->viewangle;
  }

  // cph - replaced old code, which was unclear and badly commented
  // Much more efficient code now
  if ((signed)angle1 < (signed)angle2)
  { /* it's "behind" us */
    /* Either angle1 or angle2 is behind us, so it doesn't matter if we
     * change it to the corect sign
     */
    if ((angle1 >= ANG180) && (angle1 < ANG270))
      angle1 = INT_MAX; /* which is ANG180-1 */
    else
      angle2 = INT_MIN;
  }

  if ((signed)angle2 >= (signed)clipangle) return false; // Both off left edge
  if ((signed)angle1 <= -(signed)clipangle) return false; // Both off right edge
  if ((signed)angle1 >= (signed)clipangle) angle1 = clipangle; // Clip at left edge
  if ((signed)angle2 <= -(signed)clipangle) angle2 = 0-clipangle; // Clip at right edge

  // Find the first clippost
  //  that touches the source post
  //  (adjacent pixels are touching).
  angle1 = (angle1+ANG90)>>ANGLETOFINESHIFT;
  angle2 = (angle2+ANG90)>>ANGLETOFINESHIFT;
  {
    int sx1 = viewangletox[angle1];
    int sx2 = viewangletox[angle2];
    //    const cliprange_t *start;

    // Does not cross a pixel.
    if (sx1 == sx2)
      return false;

    if (!memchr(_g->solidcol+sx1, 0, sx2-sx1)) return false;
    // All columns it covers are already solidly covered
  }

  return true;
}

//
// R_Subsector
// Determine floor/ceiling planes.
// Add sprites of things in sector.
// Draw one or more line segments.
//
// killough 1/31/98 -- made static, polished

static void R_Subsector(int num)
{
  int         count;
  seg_t       *line;
  subsector_t *sub;

#ifdef RANGECHECK
  if (num>=numsubsectors)
    I_Error ("R_Subsector: ss %i with numss = %i", num, numsubsectors);
#endif

  sub = &_g->subsectors[num];
  _g->frontsector = sub->sector;
  count = sub->numlines;
  line = &_g->segs[sub->firstline];

  if(_g->frontsector->floorheight < _g->viewz)
  {
      _g->floorplane = R_FindPlane(_g->frontsector->floorheight,
                                   _g->frontsector->floorpic,
                                   _g->frontsector->lightlevel                // killough 3/16/98
                                   );
  }
  else
  {
      _g->floorplane = NULL;
  }


  if(_g->frontsector->ceilingheight > _g->viewz || (_g->frontsector->ceilingpic == _g->skyflatnum))
  {
      _g->ceilingplane = R_FindPlane(_g->frontsector->ceilingheight,     // killough 3/8/98
                  _g->frontsector->ceilingpic,
                  _g->frontsector->lightlevel
                  );
  }
  else
  {
      _g->ceilingplane = NULL;
  }

  R_AddSprites(sub, _g->frontsector->lightlevel);
  while (count--)
  {
      R_AddLine (line);
        line++;
    _g->curline = NULL; /* cph 2001/11/18 - must clear curline now we're done with it, so R_ColourMap doesn't try using it for other things */
  }
}

//
// RenderBSPNode
// Renders all subsectors below a given node,
//  traversing subtree recursively.
// Just call with BSP root.
//
// killough 5/2/98: reformatted, removed tail recursion

void R_RenderBSPNode(int bspnum)
{
  while (!(bspnum & NF_SUBSECTOR))  // Found a subsector?
    {
      const mapnode_t *bsp = &_g->nodes[bspnum];

      // Decide which side the view point is on.
      int side = R_PointOnSide(_g->viewx, _g->viewy, bsp);
      // Recursively divide front space.
      R_RenderBSPNode(bsp->children[side]);

      // Possibly divide back space.

      if (!R_CheckBBox(bsp->bbox[side^1]))
        return;

      bspnum = bsp->children[side^1];
    }
  R_Subsector(bspnum == -1 ? 0 : bspnum & ~NF_SUBSECTOR);
}