return {
  version = "1.2",
  luaversion = "5.1",
  tiledversion = "1.2.1",
  orientation = "orthogonal",
  renderorder = "left-down",
  width = 60,
  height = 34,
  tilewidth = 16,
  tileheight = 16,
  nextlayerid = 5,
  nextobjectid = 79,
  properties = {},
  tilesets = {
    {
      name = "overworld map",
      firstgid = 1,
      filename = "../../../assets/maps/overworld-map.tsx",
      tilewidth = 17,
      tileheight = 17,
      spacing = 0,
      margin = 0,
      columns = 0,
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 1,
        height = 1
      },
      properties = {},
      terrains = {},
      tilecount = 2,
      tiles = {
        {
          id = 2,
          image = "../../../assets/sprites/custom-art/gui/gui-map-portal-point.png",
          width = 17,
          height = 17
        },
        {
          id = 3,
          image = "../../../assets/sprites/custom-art/gui/gui-map-quest-point.png",
          width = 13,
          height = 13
        }
      }
    }
  },
  layers = {
    {
      type = "objectgroup",
      id = 2,
      name = "areas",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      draworder = "topdown",
      properties = {},
      objects = {
        {
          id = 69,
          name = "",
          type = "portalPoint",
          shape = "point",
          x = 64,
          y = 96,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["area"] = "1_1"
          }
        },
        {
          id = 70,
          name = "",
          type = "portalPoint",
          shape = "point",
          x = 144,
          y = 96,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["area"] = "1_2"
          }
        },
        {
          id = 74,
          name = "",
          type = "connectionLine",
          shape = "rectangle",
          x = 64,
          y = 95,
          width = 80,
          height = 1,
          rotation = 0,
          visible = true,
          properties = {}
        }
      }
    },
    {
      type = "objectgroup",
      id = 4,
      name = "text",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      draworder = "topdown",
      properties = {},
      objects = {
        {
          id = 71,
          name = "",
          type = "",
          shape = "text",
          x = 32,
          y = 48,
          width = 64,
          height = 19,
          rotation = 0,
          visible = true,
          text = "Floor 1",
          fontfamily = "M41_LOVEBIT",
          pixelsize = 8,
          wrap = true,
          color = { 255, 255, 255 },
          halign = "center",
          properties = {}
        },
        {
          id = 73,
          name = "",
          type = "",
          shape = "text",
          x = 112,
          y = 48,
          width = 64,
          height = 19,
          rotation = 0,
          visible = true,
          text = "Floor 2",
          fontfamily = "M41_LOVEBIT",
          pixelsize = 8,
          wrap = true,
          color = { 255, 255, 255 },
          halign = "center",
          properties = {}
        },
        {
          id = 75,
          name = "",
          type = "",
          shape = "text",
          x = 48,
          y = 16,
          width = 112,
          height = 19,
          rotation = 0,
          visible = true,
          text = "Aureus",
          fontfamily = "M41_LOVEBIT",
          wrap = true,
          color = { 255, 255, 255 },
          halign = "center",
          properties = {}
        }
      }
    }
  }
}
