
local typeMaps = mjrequire "common/typeMaps"

local mjm = mjrequire "common/mjm"
local vec3 = mjm.vec3
local mat3 = mjm.mat3
local mat3Rotate = mjm.mat3Rotate
local vec3xMat3 = mjm.vec3xMat3
local mat3Identity = mjm.mat3Identity
--local approxEqual = mjm.approxEqual

local snapGroup = {}

local slightAvoidenceHeursticWeight = 0.8

local triFloor2m_inradius = 0.57735027 -- on a 2m edge equilateral triangle, it is this distance from the center of the triangle to the center of any edge
local triFloor2m_circumradius = triFloor2m_inradius * 2.0 -- on a 2m edge equilateral triangle, it is this distance from the center of the triangle to any corner

local triFloorRotMatrixA = mat3Rotate(mat3Identity, 2.0 * math.pi / 3.0, vec3(0.0,1.0,0.0))
local triFloorRotMatrixB = mat3Rotate(mat3Identity, -2.0 * math.pi / 3.0, vec3(0.0,1.0,0.0))

snapGroup.maleTypes = typeMaps:createMap("snapGroupMaleType", {
	{
		key = "wallEdgeBottomX",
	},
	{
		key = "wallMiddleBottomZ",
	},
	{
		key = "thinWallMiddleBottomZ",
	},
	{
		key = "wallMiddleTopZ",
	},
	{
		key = "thinWallMiddleTopZ",
	},
	{
		key = "roof",
	},
	{
		key = "roofEnd",
	},
	{
		key = "floor2x2",
	},
	{
		key = "roofEndWall",
	},
	{
		key = "floor4x4",
	},
	{
		key = "floor4x4Quarter",
	},
	{
		key = "largeRoofSideLeft",
	},
	{
		key = "largeRoofSideRight",
	},
	{
		key = "largeRoofTop",
	},
	{
		key = "onFloor2x2",
	},
	{
		key = "onFloor1x1",
	},
	{
		key = "steps1p5Bottom",
	},
	{
		key = "steps1p5Top",
	},
	{
		key = "steps2HalfBottom",
	},
	{
		key = "steps2HalfTop",
	},
	{
		key = "floor4x4Center",
	},
	{
		key = "column",
	},
	{
		key = "floor2x2Up"
	},
	{
		key = "floor4x4Up"
	},
	{
		key = "floorTri2",
	},
	{
		key = "floorTri2Up",
	},
	{
		key = "roofInvertedTriangleFarTopLine",
	},
	{
		key = "shelfBackCenter",
	},
	{
		key = "toolRackBackCenter",
	},
})

local femalePoints = {}
snapGroup.femalePoints = femalePoints

femalePoints.floor2x2FemaleSnapPoints = {
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},

	
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	
	
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},

	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},

	
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
}


femalePoints.onFloor2x2FemaleSnapPoints = {
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},

	

	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floor4x4Center.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floor4x4Center.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floor4x4Center.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floor4x4Center.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floor4x4Center.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floor4x4Center.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floor4x4Center.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floor4x4Center.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	
}

for x=-1,1 do
	for z = -1,1 do
		
		table.insert(femalePoints.floor2x2FemaleSnapPoints, {
			point = vec3(x, 0.0, z),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		})
		table.insert(femalePoints.floor2x2FemaleSnapPoints, {
			point = vec3(x, 0.0, z),
			normal = vec3(0.0, -1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		})

		table.insert(femalePoints.onFloor2x2FemaleSnapPoints, {
			point = vec3(x, 0.0, z),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		})
		table.insert(femalePoints.onFloor2x2FemaleSnapPoints, {
			point = vec3(x, 0.0, z),
			normal = vec3(0.0, -1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		})
	end
end


for x=0,3 do
	for z = 0,2 do
		local xPos = -1.5 + x
		local zPos = -1.0 + z

		-- z direction snapping
		table.insert(femalePoints.floor2x2FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
		table.insert(femalePoints.floor2x2FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
		table.insert(femalePoints.onFloor2x2FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
		table.insert(femalePoints.onFloor2x2FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})

		
		-- x direction snapping, swap x and z
		xPos = -1.0 + z
		zPos = -1.5 + x

		table.insert(femalePoints.floor2x2FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(1.0, 0.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
		table.insert(femalePoints.floor2x2FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(-1.0, 0.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
		table.insert(femalePoints.onFloor2x2FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(1.0, 0.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
		table.insert(femalePoints.onFloor2x2FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(-1.0, 0.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
	end
end



femalePoints.onFloor1x1FemaleSnapPoints = {
	{
		point = vec3(0.0, 0.0, 0.5),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 0.5),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
}

for x=0,1 do
	local xzPos = -0.5 + x
	local normalDirection = 1.0
	if x == 0 then
		normalDirection = -1.0
	end
	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(xzPos, 0.0, 0.0),
		normal = vec3(normalDirection, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	})
	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(0.0, 0.0, xzPos),
		normal = vec3(0.0, 0.0, normalDirection),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	})
	for z=0,1 do
		local zPos = -0.5 + z
		table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
			point = vec3(xzPos, 0.0, zPos),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		})
	end
end

for x=0,3 do
	local xzPos = -1.5 + x
	local maleSnapGroups = {
		snapGroup.maleTypes.wallMiddleBottomZ.index,
	}
	if x > 0 and x < 3 then
		table.insert(maleSnapGroups, snapGroup.maleTypes.thinWallMiddleBottomZ.index)
		table.insert(maleSnapGroups, snapGroup.maleTypes.floor2x2.index)
		table.insert(maleSnapGroups, snapGroup.maleTypes.onFloor2x2.index)
		table.insert(maleSnapGroups, snapGroup.maleTypes.floor4x4.index)
		table.insert(maleSnapGroups, snapGroup.maleTypes.floor4x4Quarter.index)
		table.insert(maleSnapGroups, snapGroup.maleTypes.floor4x4Center.index)
		table.insert(maleSnapGroups, snapGroup.maleTypes.floorTri2.index)
	end

	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(xzPos, 0.0, -0.5),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = maleSnapGroups,
	})
	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(xzPos, 0.0, -0.5),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = maleSnapGroups,
	})
	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(xzPos, 0.0, 0.5),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = maleSnapGroups,
	})
	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(xzPos, 0.0, 0.5),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = maleSnapGroups,
	})
	
	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(-0.5, 0.0, xzPos),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = maleSnapGroups,
	})
	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(-0.5, 0.0, xzPos),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = maleSnapGroups,
	})
	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(0.5, 0.0, xzPos),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = maleSnapGroups,
	})
	table.insert(femalePoints.onFloor1x1FemaleSnapPoints, {
		point = vec3(0.5, 0.0, xzPos),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = maleSnapGroups,
	})
end


femalePoints.floor4x4FemaleSnapPoints = {

	{
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	
	{
		point = vec3(2.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(2.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	

	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.roof.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.roof.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.roof.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.roof.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	

	{
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
			snapGroup.maleTypes.steps2HalfTop.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
			snapGroup.maleTypes.steps2HalfTop.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
			snapGroup.maleTypes.steps2HalfTop.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
			snapGroup.maleTypes.steps2HalfTop.index,
		},
	},

	{
		point = vec3(2.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(2.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},

	
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},


	
	{
		point = vec3(2.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(2.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	
	{
		point = vec3(1.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},

	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},

	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},

	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps1p5Bottom.index,
		},
	},

	
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
		heuristicWeight = slightAvoidenceHeursticWeight,
	},

}

for x=-2,2 do
	for z = -2,2 do
		table.insert(femalePoints.floor4x4FemaleSnapPoints, {
			point = vec3(x, 0.0, z),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		})
		table.insert(femalePoints.floor4x4FemaleSnapPoints, {
			point = vec3(x, 0.0, z),
			normal = vec3(0.0, -1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		})
	end
end


for x=0,5 do
	for z = 0,4 do
		local xPos = -2.5 + x
		local zPos = -2.0 + z

		-- z direction snapping
		table.insert(femalePoints.floor4x4FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
		table.insert(femalePoints.floor4x4FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})

		
		-- x direction snapping, swap x and z
		xPos = -1.0 + z
		zPos = -1.5 + x

		table.insert(femalePoints.floor4x4FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(1.0, 0.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
		table.insert(femalePoints.floor4x4FemaleSnapPoints, {
			point = vec3(xPos, 0.0, zPos),
			normal = vec3(-1.0, 0.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.onFloor1x1.index,
			},
		})
	end
end

femalePoints.onFloor4x4FemaleSnapPoints = femalePoints.floor4x4FemaleSnapPoints --WARNING if you're going to modify this, you will need to do a clone first

femalePoints.floorTri2FemaleSnapPoints = {
	{
		point = vec3(0.0, 0.0, -triFloor2m_circumradius),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixA),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -triFloor2m_circumradius),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixB),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},

	{
		point = vec3(0.0, 2.0, triFloor2m_inradius),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.0, 2.0, triFloor2m_inradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixA),
		maleSnapGroups = {
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.0, 2.0, triFloor2m_inradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixB),
		maleSnapGroups = {
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixB),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixA),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	
	{
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixA),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixB),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
		},
	},

	{
		point = vec3(0.0, 0.0, triFloor2m_inradius),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.0, 0.0, triFloor2m_inradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixA),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.0, 0.0, triFloor2m_inradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixB),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	
	-- flipped normal
	{
		point = vec3(0.0, 0.0, triFloor2m_inradius),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.0, 0.0, triFloor2m_inradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixA),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.0, 0.0, triFloor2m_inradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixB),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(0.5, 0.0, triFloor2m_inradius),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	{
		point = vec3(-0.5, 0.0, triFloor2m_inradius),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.5, 0.0, triFloor2m_inradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixA),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	{
		point = vec3xMat3(vec3(-0.5, 0.0, triFloor2m_inradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixA),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	{
		point = vec3xMat3(vec3(0.5, 0.0, triFloor2m_inradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixB),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	{
		point = vec3xMat3(vec3(-0.5, 0.0, triFloor2m_inradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixB),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
}

local baseColumnMatrix = mat3(
	1,0,0,
	0,0,-1,
	0,1,0
)
local baseColumnMatrixReverse = mat3(
	-1,0,0,
	0,0,1,
	0,1,0
)

local baseColumnMatrixDown = mat3(
	1,0,0,
	0,0,1,
	0,-1,0
)
local baseColumnMatrixDownReverse = mat3(
	-1,0,0,
	0,0,-1,
	0,-1,0
)


local columnMatrices = {
	baseColumnMatrix,
	triFloorRotMatrixA * baseColumnMatrix,
	triFloorRotMatrixB * baseColumnMatrix,
	baseColumnMatrixReverse,
	triFloorRotMatrixA * baseColumnMatrixReverse,
	triFloorRotMatrixB * baseColumnMatrixReverse,
	baseColumnMatrixDown,
	triFloorRotMatrixA * baseColumnMatrixDown,
	triFloorRotMatrixB * baseColumnMatrixDown,
	baseColumnMatrixDownReverse,
	triFloorRotMatrixA * baseColumnMatrixDownReverse,
	triFloorRotMatrixB * baseColumnMatrixDownReverse,
}

for i=1,#columnMatrices do
	table.insert(femalePoints.floorTri2FemaleSnapPoints, {
		point = vec3(0.0, 0.0, -triFloor2m_circumradius),
		matrix = columnMatrices[i],
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
	table.insert(femalePoints.floorTri2FemaleSnapPoints, {
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixA),
		matrix = columnMatrices[i],
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
	table.insert(femalePoints.floorTri2FemaleSnapPoints, {
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixB),
		matrix = columnMatrices[i],
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
end

local function wallFemaleSnapPointsForHeight(wallHeight, wallWidth)

	local result = {
		{
			point = vec3(0.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.roof.index,
				snapGroup.maleTypes.roofEndWall.index,
			},
		},
		{
			point = vec3(0.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.roof.index,
				snapGroup.maleTypes.roofEndWall.index,
			},
		},
	}

	
	if wallWidth < 2.1 then
		table.insert(result, {
			point = vec3(-1.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.roof.index,
				snapGroup.maleTypes.roofEndWall.index,
			},
		})
		table.insert(result, {
			point = vec3(-1.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.roof.index,
				snapGroup.maleTypes.roofEndWall.index,
			},
		})
		table.insert(result, {
			point = vec3(1.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.roof.index,
				snapGroup.maleTypes.roofEndWall.index,
			},
		})
		table.insert(result, {
			point = vec3(1.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.roof.index,
				snapGroup.maleTypes.roofEndWall.index,
			},
		})
	end

	local floorSnapPoints = nil

	if wallWidth < 2.1 then
		floorSnapPoints = {
			{
				point = vec3(0.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.onFloor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
				},
			},
			{
				point = vec3(0.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.onFloor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
				},
			},
			
			{
				point = vec3(0.5, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.onFloor1x1.index,
				},
			},
			{
				point = vec3(0.5, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.onFloor1x1.index,
				},
			},
			{
				point = vec3(-0.5, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.onFloor1x1.index,
				},
			},
			{
				point = vec3(-0.5, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.onFloor1x1.index,
				},
			},

			{
				point = vec3(0.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.onFloor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
				},
			},
			{
				point = vec3(10.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.onFloor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
				},
			},
			
			
			{
				point = vec3(1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(-1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(-1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(0.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(0.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			

			
			{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(0.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(0.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
		}
	else
		floorSnapPoints = {
			{
				point = vec3(1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
					snapGroup.maleTypes.onFloor2x2.index,
				},
			},
			{
				point = vec3(1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
					snapGroup.maleTypes.onFloor2x2.index,
				},
			},
			{
				point = vec3(-1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
					snapGroup.maleTypes.onFloor2x2.index,
				},
			},
			{
				point = vec3(-1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
					snapGroup.maleTypes.onFloor2x2.index,
				},
			},
			{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
					snapGroup.maleTypes.onFloor2x2.index,
				},
			},
			{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
					snapGroup.maleTypes.onFloor2x2.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
					snapGroup.maleTypes.onFloor2x2.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor2x2.index,
					snapGroup.maleTypes.floorTri2.index,
					snapGroup.maleTypes.onFloor2x2.index,
				},
			},
			{
				point = vec3(0.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(0.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(0.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
			{
				point = vec3(0.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.floor4x4.index,
				},
			},
		}

		for x=1,4 do
			local xPos = -2.0 + 0.5 + x - 1

			table.insert(floorSnapPoints,{
				point = vec3(xPos, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.onFloor1x1.index,
				},
			})
			table.insert(floorSnapPoints,{
				point = vec3(xPos, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.onFloor1x1.index,
				},
			})
		end
	end
	
	local wallSnapPoints = nil
	local wallHalfWidth = wallWidth * 0.5

	wallSnapPoints = {
		{
			point = vec3(wallHalfWidth, 0.0, 0.0),
			normal = vec3(1.0, 0.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallEdgeBottomX.index,
			},
		},
		{
			point = vec3(-wallHalfWidth, 0.0, 0.0),
			normal = vec3(-1.0, 0.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallEdgeBottomX.index,
			},
		},
		{
			point = vec3(wallHalfWidth, 0.0, 0.0),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallEdgeBottomX.index,
			},
		},
		{
			point = vec3(wallHalfWidth, 0.0, 0.0),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallEdgeBottomX.index,
			},
		},
		{
			point = vec3(-wallHalfWidth, 0.0, 0.0),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallEdgeBottomX.index,
			},
		},
		{
			point = vec3(-wallHalfWidth, 0.0, 0.0),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallEdgeBottomX.index,
			},
		},
		{
			point = vec3(0.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallMiddleBottomZ.index,
			},
		},
		{
			point = vec3(0.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallMiddleBottomZ.index,
			},
		},
		{
			point = vec3(0.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			},
		},
		{
			point = vec3(0.0, wallHeight, 0.0),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.thinWallMiddleBottomZ.index,
			},
		},
		{
			point = vec3(0.0, 0.0, 0.0),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallMiddleTopZ.index,
			},
		},
		{
			point = vec3(0.0, 0.0, 0.0),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.wallMiddleTopZ.index,
			},
		},
		{
			point = vec3(0.0, 0.0, 0.0),
			normal = vec3(0.0, 0.0, -1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.thinWallMiddleTopZ.index,
				snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			},
		},
		{
			point = vec3(0.0, 0.0, 0.0),
			normal = vec3(0.0, 0.0, 1.0),
			maleSnapGroups = {
				snapGroup.maleTypes.thinWallMiddleTopZ.index,
				snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			},
		},
	}

	if wallWidth > 2.1 then
		local additionalWallSnapPoints = {
			{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.thinWallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.thinWallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.thinWallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.thinWallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.thinWallMiddleTopZ.index,
					snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
				},
			},
			{
				point = vec3(1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.thinWallMiddleTopZ.index,
					snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
				},
			},
			{
				point = vec3(-1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.thinWallMiddleTopZ.index,
					snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
				},
			},
			{
				point = vec3(-1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.thinWallMiddleTopZ.index,
					snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
				},
			},

		}

		for y = 0,4 do
			if (0.5 * y) > (wallHeight + 0.1) then
				break
			end

			local maleSnapGroups = {
				snapGroup.maleTypes.shelfBackCenter.index,
			}

			if y > 0 and y % 2 == 0 then
				table.insert(maleSnapGroups, snapGroup.maleTypes.toolRackBackCenter.index)
			end

			table.insert(additionalWallSnapPoints, {
				point = vec3(-1.0, 0.5 * y, 0.1),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = maleSnapGroups,
			})
			table.insert(additionalWallSnapPoints, {
				point = vec3(1.0, 0.5 * y, 0.1),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = maleSnapGroups,
			})
			table.insert(additionalWallSnapPoints, {
				point = vec3(-1.0, 0.5 * y, -0.1),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = maleSnapGroups,
			})
			table.insert(additionalWallSnapPoints, {
				point = vec3(1.0, 0.5 * y, -0.1),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = maleSnapGroups,
			})
		end
		
		for i,info in ipairs(additionalWallSnapPoints) do
			table.insert(wallSnapPoints, info)
		end
	else
		local additionalWallSnapPoints = {
			{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleBottomZ.index,
				},
			},

			{
				point = vec3(1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleTopZ.index,
				},
			},
			{
				point = vec3(1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleTopZ.index,
				},
			},

			{
				point = vec3(-1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleTopZ.index,
				},
			},
			{
				point = vec3(-1.0, 0.0, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleTopZ.index,
				},
			},
		}
		

		for y = 0,4 do
			if (0.5 * y) > (wallHeight + 0.1) then
				break
			end

			local maleSnapGroups = {
				snapGroup.maleTypes.shelfBackCenter.index,
			}

			if y > 0 and y % 2 == 0 then
				table.insert(maleSnapGroups, snapGroup.maleTypes.toolRackBackCenter.index)
			end

			table.insert(additionalWallSnapPoints, {
				point = vec3(0.0, 0.5 * y, 0.1),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = maleSnapGroups,
			})
			table.insert(additionalWallSnapPoints, {
				point = vec3(0.0, 0.5 * y, -0.1),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = maleSnapGroups,
			})
		end
		
		for i,info in ipairs(additionalWallSnapPoints) do
			table.insert(wallSnapPoints, info)
		end
	end
		
	
	local columnSnapPoints = nil

	columnSnapPoints = {
		{
			point = vec3(0.0, 0.0, 0.0),
			normal = vec3(0.0, -1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		},
		{
			point = vec3(1.0, 0.0, 0.0),
			normal = vec3(0.0, -1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		},
		{
			point = vec3(-1.0, 0.0, 0.0),
			normal = vec3(0.0, -1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		},
		{
			point = vec3(0.0, 0.0, 0.0),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		},
		{
			point = vec3(1.0, 0.0, 0.0),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		},
		{
			point = vec3(-1.0, 0.0, 0.0),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		},
		{
			point = vec3(0.0, wallHeight, 0.0),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		},
		{
			point = vec3(1.0, wallHeight, 0.0),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		},
		{
			point = vec3(-1.0, wallHeight, 0.0),
			normal = vec3(0.0, 1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		},
	}
	
	if wallWidth > 2.1 then
		local additionalColumnSnapPoints = {
			
			{
				point = vec3(2.0, 0.0, 0.0),
				normal = vec3(0.0, -1.0, 0.0),
				maleSnapGroups = {
					snapGroup.maleTypes.column.index,
				},
			},
			{
				point = vec3(-2.0, 0.0, 0.0),
				normal = vec3(0.0, -1.0, 0.0),
				maleSnapGroups = {
					snapGroup.maleTypes.column.index,
				},
			},
			{
				point = vec3(2.0, 0.0, 0.0),
				normal = vec3(0.0, 1.0, 0.0),
				maleSnapGroups = {
					snapGroup.maleTypes.column.index,
				},
			},
			{
				point = vec3(-2.0, 0.0, 0.0),
				normal = vec3(0.0, 1.0, 0.0),
				maleSnapGroups = {
					snapGroup.maleTypes.column.index,
				},
			},
			
			{
				point = vec3(2.0, wallHeight, 0.0),
				normal = vec3(0.0, 1.0, 0.0),
				maleSnapGroups = {
					snapGroup.maleTypes.column.index,
				},
			},
			{
				point = vec3(-2.0, wallHeight, 0.0),
				normal = vec3(0.0, 1.0, 0.0),
				maleSnapGroups = {
					snapGroup.maleTypes.column.index,
				},
			},
		}
		
		for i,info in ipairs(additionalColumnSnapPoints) do
			table.insert(columnSnapPoints, info)
		end
	end

	for i,info in ipairs(floorSnapPoints) do
		table.insert(result, info)
	end
	for i,info in ipairs(wallSnapPoints) do
		table.insert(result, info)
	end
	for i,info in ipairs(columnSnapPoints) do
		table.insert(result, info)
	end

	return result
end


femalePoints.roofEndWallFemaleSnapPoints = {
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
		},
	},
	
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
}


femalePoints.roofFemaleSnapPoints = {
	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEndWall.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEndWall.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEndWall.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEndWall.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	
	{
		point = vec3(-2.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(2.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(2.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	
	{
		point = vec3(-2.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(2.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
	{
		point = vec3(2.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.onFloor2x2.index,
		},
	},
}

femalePoints.roofSlopeFemaleSnapPoints = {
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	
	{
		point = vec3(0.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	
	{
		point = vec3(1.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	
	{
		point = vec3(-1.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},

	--[[
{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, -1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleBottomZ.index,
				},
			},
			{
				point = vec3(-1.0, wallHeight, 0.0),
				normal = vec3(0.0, 0.0, 1.0),
				maleSnapGroups = {
					snapGroup.maleTypes.wallMiddleBottomZ.index,
				},
			},
	]]
}

for x = -1,1 do
	table.insert(femalePoints.roofSlopeFemaleSnapPoints, {
		point = vec3(x, 0.0, -1.0),
		normal = vec3(0.0, 1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
	table.insert(femalePoints.roofSlopeFemaleSnapPoints, {
		point = vec3(x, 0.0, 1.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
end

femalePoints.roofSmallCornerFemaleSnapPoints = {
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
}


femalePoints.roofSmallInnerCornerFemaleSnapPoints = {
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	
	
	{
		point = vec3(1.0, 2.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 2.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 2.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
}

femalePoints.roofTriangleFemaleSnapPoints = {
	{
		point = vec3(0.0, 0.0, -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixA),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixB),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
		},
	},

	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},
}

femalePoints.roofInvertedTriangleFemaleSnapPoints = {
	{
		point = vec3(1.0, 0.0,  -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixA),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
		},
	},
	{
		point = vec3(-1.0, 0.0,  -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixB),
		maleSnapGroups = {
			snapGroup.maleTypes.roofEnd.index,
			snapGroup.maleTypes.roofEndWall.index,
		},
	},

	{
		point = vec3(0.0, 2.0, -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(0.0, 2.0, -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.wallMiddleTopZ.index,
			snapGroup.maleTypes.thinWallMiddleTopZ.index,
			snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
		},
	},

	{
		point = vec3(0.0, 2.0, -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
}


local roofWallCenterTopMaleSnapPoints = {
	snapGroup.maleTypes.wallMiddleTopZ.index,
	snapGroup.maleTypes.thinWallMiddleTopZ.index,
	snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
}
local roofWallCenterBottomMaleSnapPoints = {
	snapGroup.maleTypes.wallMiddleBottomZ.index,
	snapGroup.maleTypes.thinWallMiddleBottomZ.index,
}


local roofWallHalfTopMaleSnapPoints = {
	snapGroup.maleTypes.thinWallMiddleTopZ.index,
	snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
}
local roofWallHalfBottomMaleSnapPoints = {
	snapGroup.maleTypes.thinWallMiddleBottomZ.index,
}

for x = -1,1 do
	local maleSnapGroupsToUse = roofWallHalfTopMaleSnapPoints
	if x == 0 then
		maleSnapGroupsToUse = roofWallCenterTopMaleSnapPoints
	end
	
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(x, 0.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = maleSnapGroupsToUse,
	})
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(x, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = maleSnapGroupsToUse,
	})
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(x, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = maleSnapGroupsToUse,
	})
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(x, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = maleSnapGroupsToUse,
	})
	
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(-2.0, 0.0, x),
		normal = vec3(1.0, 0.0, 0),
		maleSnapGroups = maleSnapGroupsToUse,
	})
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(-2.0, 0.0, x),
		normal = vec3(-1.0, 0.0, 0),
		maleSnapGroups = maleSnapGroupsToUse,
	})
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(2.0, 0.0, x),
		normal = vec3(1.0, 0.0, 0),
		maleSnapGroups = maleSnapGroupsToUse,
	})
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(2.0, 0.0, x),
		normal = vec3(-1.0, 0.0, 0),
		maleSnapGroups = maleSnapGroupsToUse,
	})
end

for z = -2,2 do
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(-2, 0.0, z),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(0, 0.0, z),
		normal = vec3(0.0, 1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
	table.insert(femalePoints.roofFemaleSnapPoints, {
		point = vec3(2, 0.0, z),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
end


femalePoints.largeRoofFemaleSnapPoints = {
	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},

	{
		point = vec3(0.0, 4.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.roof.index,
		},
	},
	
	{
		point = vec3(0.0, 4.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.largeRoofTop.index,
		},
	},
	
	{
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.largeRoofSideLeft.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.largeRoofSideRight.index,
		},
	},

}

for x = -1,1 do
	local topMaleSnapGroupsToUse = roofWallHalfTopMaleSnapPoints
	local bottomMaleSnapGroupsToUse = roofWallHalfBottomMaleSnapPoints
	if x == 0 then
		topMaleSnapGroupsToUse = roofWallCenterTopMaleSnapPoints
		bottomMaleSnapGroupsToUse = roofWallCenterBottomMaleSnapPoints
	end
	
	table.insert(femalePoints.largeRoofFemaleSnapPoints, {
		point = vec3(x, 4.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = bottomMaleSnapGroupsToUse,
	})
	table.insert(femalePoints.largeRoofFemaleSnapPoints, {
		point = vec3(x, 4.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = bottomMaleSnapGroupsToUse,
	})

	
	table.insert(femalePoints.largeRoofFemaleSnapPoints, {
		point = vec3(x, 4.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = topMaleSnapGroupsToUse,
	})
	table.insert(femalePoints.largeRoofFemaleSnapPoints, {
		point = vec3(x, 4.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = topMaleSnapGroupsToUse,
	})
	table.insert(femalePoints.largeRoofFemaleSnapPoints, {
		point = vec3(x, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = topMaleSnapGroupsToUse,
	})
	table.insert(femalePoints.largeRoofFemaleSnapPoints, {
		point = vec3(x, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = topMaleSnapGroupsToUse,
	})
end

for x = -2,2 do
	table.insert(femalePoints.largeRoofFemaleSnapPoints, {
		point = vec3(x, 0.0, 2),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
end

femalePoints.largeRoofCornerFemaleSnapPoints = {
	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},

	
	{
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.largeRoofTop.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.largeRoofTop.index,
		},
	},
	
	{
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.largeRoofSideLeft.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.largeRoofSideRight.index,
		},
	},

}


for xz = -1,1 do
	local topMaleSnapGroupsToUse = roofWallHalfTopMaleSnapPoints
	if xz == 0 then
		topMaleSnapGroupsToUse = roofWallCenterTopMaleSnapPoints
	end
	
	table.insert(femalePoints.largeRoofCornerFemaleSnapPoints, {
		point = vec3(xz, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = topMaleSnapGroupsToUse,
	})
	table.insert(femalePoints.largeRoofCornerFemaleSnapPoints, {
		point = vec3(xz, 0.0, 2.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = topMaleSnapGroupsToUse,
	})
	
	
	table.insert(femalePoints.largeRoofCornerFemaleSnapPoints, {
		point = vec3(-2.0, 0.0, xz),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = topMaleSnapGroupsToUse,
	})
	table.insert(femalePoints.largeRoofCornerFemaleSnapPoints, {
		point = vec3(-2.0, 0.0, xz),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = topMaleSnapGroupsToUse,
	})
end

for xz = -2,2 do
	table.insert(femalePoints.largeRoofCornerFemaleSnapPoints, {
		point = vec3(xz, 0.0, 2),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	})
	if xz ~= 2 then
		table.insert(femalePoints.largeRoofCornerFemaleSnapPoints, {
			point = vec3(-2, 0.0, xz),
			normal = vec3(0.0, -1.0, 0.0),
			maleSnapGroups = {
				snapGroup.maleTypes.column.index,
			},
		})
	end
end

femalePoints.steps1p5FemaleSnapPoints = {
	{
		point = vec3(0.0, 0.0, 1.5),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
		},
	},
	{
		point = vec3(0.0, 2.0, -1.5),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Bottom.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(-1.0, 2.0, -1.5),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(0.0, 2.0, -1.5),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(1.0, 2.0, -1.5),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
}

femalePoints.steps2HalfFemaleSnapPoints = {
	{
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Top.index,
			snapGroup.maleTypes.steps2HalfTop.index,
		},
	},
	{
		point = vec3(0.0, 1.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floor4x4.index,
			snapGroup.maleTypes.floor4x4Quarter.index,
			snapGroup.maleTypes.floorTri2.index,
			snapGroup.maleTypes.steps1p5Bottom.index,
			snapGroup.maleTypes.steps2HalfBottom.index,
		},
	},
	{
		point = vec3(-1.0, 1.0, -1.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(0.0, 1.0, -1.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(1.0, 1.0, -1.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
}

femalePoints.horizontalColumnFemaleSnapPoints = {
	{
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},

	--- a
	{
		point = vec3(1.0, 0.0, 0.0),
		matrix = mat3(
			0,0,1,
			1,0,0,
			0,1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		matrix = mat3(
			0,1,0,
			1,0,0,
			0,0,-1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		matrix = mat3(
			0,0,-1,
			1,0,0,
			0,-1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		matrix = mat3(
			0,-1,0,
			1,0,0,
			0,0,1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	--- b
	{
		point = vec3(1.0, 0.0, 0.0),
		matrix = mat3(
			0,0,1,
			-1,0,0,
			0,-1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		matrix = mat3(
			0,1,0,
			-1,0,0,
			0,0,1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		matrix = mat3(
			0,0,-1,
			-1,0,0,
			0,1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(1.0, 0.0, 0.0),
		matrix = mat3(
			0,-1,0,
			-1,0,0,
			0,0,-1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	--- c
	{
		point = vec3(-1.0, 0.0, 0.0),
		matrix = mat3(
			0,0,1,
			-1,0,0,
			0,-1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		matrix = mat3(
			0,1,0,
			-1,0,0,
			0,0,1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		matrix = mat3(
			0,0,-1,
			-1,0,0,
			0,1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		matrix = mat3(
			0,-1,0,
			-1,0,0,
			0,0,-1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	--- d
	{
		point = vec3(-1.0, 0.0, 0.0),
		matrix = mat3(
			0,0,1,
			1,0,0,
			0,1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		matrix = mat3(
			0,1,0,
			1,0,0,
			0,0,-1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		matrix = mat3(
			0,0,-1,
			1,0,0,
			0,-1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, 0.0),
		matrix = mat3(
			0,-1,0,
			1,0,0,
			0,0,1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
}


for x=-2,2 do
	table.insert(femalePoints.horizontalColumnFemaleSnapPoints, {
		point = vec3(-1.0, 0.0, x),
		matrix = mat3(
			0,0,-1,
			-1,0,0,
			0,1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	table.insert(femalePoints.horizontalColumnFemaleSnapPoints, {
		point = vec3(-1.0, 0.0, x),
		matrix = mat3(
			0,0,1,
			1,0,0,
			0,1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	
	table.insert(femalePoints.horizontalColumnFemaleSnapPoints, {
		point = vec3(-1.0, x, 0.0),
		matrix = mat3(
			0,1,0,
			-1,0,0,
			0,0,1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	
	table.insert(femalePoints.horizontalColumnFemaleSnapPoints, {
		point = vec3(-1.0, x, 0.0),
		matrix = mat3(
			0,1,0,
			1,0,0,
			0,0,-1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})

	--- b
	
	table.insert(femalePoints.horizontalColumnFemaleSnapPoints, {
		point = vec3(1.0, 0.0, x),
		matrix = mat3(
			0,0,1,
			1,0,0,
			0,1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	table.insert(femalePoints.horizontalColumnFemaleSnapPoints, {
		point = vec3(1.0, 0.0, x),
		matrix = mat3(
			0,0,-1,
			-1,0,0,
			0,1,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	
	table.insert(femalePoints.horizontalColumnFemaleSnapPoints, {
		point = vec3(1.0, x, 0.0),
		matrix = mat3(
			0,1,0,
			-1,0,0,
			0,0,1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	
	table.insert(femalePoints.horizontalColumnFemaleSnapPoints, {
		point = vec3(1.0, x, 0.0),
		matrix = mat3(
			0,1,0,
			1,0,0,
			0,0,-1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
end

femalePoints.verticalColumnFemaleSnapPoints = {
	{
		point = vec3(0.0, 2.0, 0.0),
		normal = vec3(0.0, 1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, -1.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.column.index,
		},
	},

	
	{
		point = vec3(0.0, 2.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(0.0, 2.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(0.0, 2.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(0.0, 2.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(0.0, -0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
	{
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2Up.index,
			snapGroup.maleTypes.floor4x4Up.index,
			snapGroup.maleTypes.floorTri2Up.index,
		},
	},
}



for x=-2,2 do
	table.insert(femalePoints.verticalColumnFemaleSnapPoints, {
		point = vec3(x, 0.0, 0),
		matrix = mat3(
			1,0,0,
			0,1,0,
			0,0,1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	table.insert(femalePoints.verticalColumnFemaleSnapPoints, {
		point = vec3(x, 0.0, 0),
		matrix = mat3(
			1,0,0,
			0,-1,0,
			0,0,-1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	table.insert(femalePoints.verticalColumnFemaleSnapPoints, {
		point = vec3(0.0, 0.0, x),
		matrix = mat3(
			0,0,1,
			0,1,0,
			-1,0,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	table.insert(femalePoints.verticalColumnFemaleSnapPoints, {
		point = vec3(0.0, 0.0, x),
		matrix = mat3(
			0,0,1,
			0,-1,0,
			1,0,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})

	--- b

	

	table.insert(femalePoints.verticalColumnFemaleSnapPoints, {
		point = vec3(x, 2.0, 0),
		matrix = mat3(
			1,0,0,
			0,1,0,
			0,0,1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	table.insert(femalePoints.verticalColumnFemaleSnapPoints, {
		point = vec3(x, 2.0, 0),
		matrix = mat3(
			1,0,0,
			0,-1,0,
			0,0,-1
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	table.insert(femalePoints.verticalColumnFemaleSnapPoints, {
		point = vec3(0.0, 2.0, x),
		matrix = mat3(
			0,0,1,
			0,1,0,
			-1,0,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
	table.insert(femalePoints.verticalColumnFemaleSnapPoints, {
		point = vec3(0.0, 2.0, x),
		matrix = mat3(
			0,0,1,
			0,-1,0,
			1,0,0
		),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	})
end

femalePoints.standardWallFemaleSnapPoints = wallFemaleSnapPointsForHeight(2.0, 4.0)
femalePoints.shortWall4x1FemaleSnapPoints = wallFemaleSnapPointsForHeight(1.0, 4.0)
femalePoints.wall2x2FemaleSnapPoints = wallFemaleSnapPointsForHeight(2.0, 2.0)
femalePoints.wall2x1FemaleSnapPoints = wallFemaleSnapPointsForHeight(1.0, 2.0)

--mj:log("femalePoints.wall2x1FemaleSnapPoints:", femalePoints.wall2x1FemaleSnapPoints)

femalePoints.toolRackFemaleSnapPoints = {
	
	{
		point = vec3(0.0, 2.0, -0.2),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.toolRackBackCenter.index,
		},
	},
	{
		point = vec3(0.0, 1.0, -0.2),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.toolRackBackCenter.index,
		},
	},

	{
		point = vec3(0.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
			snapGroup.maleTypes.thinWallMiddleBottomZ.index,
		},
	},

	{
		point = vec3(1.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},

	{
		point = vec3(-1.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.wallMiddleBottomZ.index,
		},
	},

	--[[{
		point = vec3(0.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor2x2.index,
			snapGroup.maleTypes.onFloor2x2.index,
			snapGroup.maleTypes.floorTri2.index,
		},
	},
	{
		point = vec3(0.5, 0.0, -0.3),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	{
		point = vec3(0.5, 0.0, -0.3),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	{
		point = vec3(-0.5, 0.0, -0.3),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	{
		point = vec3(-0.5, 0.0, -0.3),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.onFloor1x1.index,
		},
	},
	
	{
		point = vec3(1.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(1.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(-1.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, -1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},
	{
		point = vec3(0.0, 0.0, -0.3),
		normal = vec3(0.0, 0.0, 1.0),
		maleSnapGroups = {
			snapGroup.maleTypes.floor4x4.index,
		},
	},]]
}

---------------------------------|------|----------------------------------------
-------------------------------- | MALE | ---------------------------------------
---------------------------------V------V----------------------------------------


local malePoints = {}
snapGroup.malePoints = malePoints

malePoints.roofMaleSnapPoints = {
	{
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
}


for x=-1,1 do
	for z = -2,2 do
		table.insert(malePoints.roofMaleSnapPoints, {
			snapGroup = snapGroup.maleTypes.floor4x4Up.index,
			point = vec3(x * 2, 0.0, z),
			normal = vec3(0.0, 0.0, 1.0),
		})
	end
end

malePoints.roofSlopeMaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
    {
        snapGroup = snapGroup.maleTypes.thinWallMiddleBottomZ.index,
        point = vec3(0.0, 0.0, 1.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
}

malePoints.roofLargeMaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.largeRoofTop.index,
		point = vec3(0.0, 4.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.largeRoofSideRight.index,
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.largeRoofSideLeft.index,
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
}

for x = -2,2 do
	table.insert(malePoints.roofLargeMaleSnapPoints, {
		snapGroup = snapGroup.maleTypes.floor4x4Up.index,
		point = vec3(x * 2, 0.0, 2),
		normal = vec3(0.0, 0.0, 1.0),
	})
end

malePoints.roofLargeCornerMaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.largeRoofSideRight.index,
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.largeRoofSideLeft.index,
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
}
for x = -2,2 do
	table.insert(malePoints.roofLargeCornerMaleSnapPoints, {
		snapGroup = snapGroup.maleTypes.floor4x4Up.index,
		point = vec3(x * 2, 0.0, 2),
		normal = vec3(0.0, 0.0, 1.0),
	})
end
for z = -2,1 do
	table.insert(malePoints.roofLargeCornerMaleSnapPoints, {
		snapGroup = snapGroup.maleTypes.floor4x4Up.index,
		point = vec3(-2, 0.0, z),
		normal = vec3(-1.0, 0.0, 0.0),
	})
end

malePoints.roofLargeInnerCornerMaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.largeRoofSideRight.index,
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.largeRoofSideLeft.index,
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.floor4x4Up.index,
		point = vec3(-2.0, 0.0, 2.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.floor4x4Up.index,
		point = vec3(-2.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
}

malePoints.roofSmallCornerMaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(1.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
}

malePoints.roofSmallInnerCornerMaleSnapPoints = {
	--[[{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},]]
	{   
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(1.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(-1.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
}

malePoints.roofTriangleMaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.roof.index,
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(0.0, 0.0, -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixA),
	},
	{
		snapGroup = snapGroup.maleTypes.roofEnd.index,
		point = vec3(0.0, 0.0, -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixB),
	},
    {
        snapGroup = snapGroup.maleTypes.thinWallMiddleBottomZ.index,
        point = vec3(0.0, 0.0, 1.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
}


malePoints.roofInvertedTriangleMaleSnapPoints = {
	{
        snapGroup = snapGroup.maleTypes.roofInvertedTriangleFarTopLine.index,
        point = vec3(0.0, 2.0, -triFloor2m_inradius * 3.0 + 1.0),
        normal = vec3(0.0, 0.0, -1.0),
    },
	{
		snapGroup = snapGroup.maleTypes.roofEnd.index,
        point = vec3(-1.0, 0.0, -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixB),
	},
	{
		snapGroup = snapGroup.maleTypes.roofEnd.index,
        point = vec3(1.0, 0.0, -triFloor2m_inradius * 3.0 + 1.0),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixA),
	},
}

malePoints.roofEndWallMaleSnapPoints = {
	{
		snapGroup = snapGroup.maleTypes.roofEndWall.index,
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.roofEndWall.index,
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
}

malePoints.wallMaleSnapPoints = {
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(-2.0, 0.0, 0.0),
        normal = vec3(-1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(2.0, 0.0, 0.0),
        normal = vec3(1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallMiddleBottomZ.index,
        point = vec3(0.0, 0.0, 0.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallMiddleBottomZ.index,
        point = vec3(0.0, 0.0, 0.0),
        normal = vec3(0.0, 0.0, -1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallMiddleTopZ.index,
        point = vec3(0.0, 2.0, 0.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallMiddleTopZ.index,
        point = vec3(0.0, 2.0, 0.0),
        normal = vec3(0.0, 0.0, -1.0),
    },
}

malePoints.wall4x1MaleSnapPoints = {
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(-2.0, 0.0, 0.0),
        normal = vec3(-1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(2.0, 0.0, 0.0),
        normal = vec3(1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallMiddleBottomZ.index,
        point = vec3(0.0, 0.0, 0.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallMiddleBottomZ.index,
        point = vec3(0.0, 0.0, 0.0),
        normal = vec3(0.0, 0.0, -1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallMiddleTopZ.index,
        point = vec3(0.0, 1.0, 0.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallMiddleTopZ.index,
        point = vec3(0.0, 1.0, 0.0),
        normal = vec3(0.0, 0.0, -1.0),
    },
}

malePoints.wall2x2MaleSnapPoints = {
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(-1.0, 0.0, 0.0),
        normal = vec3(-1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(1.0, 0.0, 0.0),
        normal = vec3(1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.thinWallMiddleBottomZ.index,
        point = vec3(0.0, 0.0, 0.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.thinWallMiddleTopZ.index,
        point = vec3(0.0, 2.0, 0.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.thinWallMiddleTopZ.index,
        point = vec3(0.0, 2.0, 0.0),
        normal = vec3(0.0, 0.0, -1.0),
    },
}

malePoints.wall2x1MaleSnapPoints = {
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(-1.0, 0.0, 0.0),
        normal = vec3(-1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(1.0, 0.0, 0.0),
        normal = vec3(1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.thinWallMiddleBottomZ.index,
        point = vec3(0.0, 0.0, 0.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.thinWallMiddleTopZ.index,
        point = vec3(0.0, 1.0, 0.0),
        normal = vec3(0.0, 0.0, 1.0),
    },
    {
        snapGroup = snapGroup.maleTypes.thinWallMiddleTopZ.index,
        point = vec3(0.0, 1.0, 0.0),
        normal = vec3(0.0, 0.0, -1.0),
    },
}

malePoints.floor2x2MaleSnapPoints = {
	{
		snapGroup = snapGroup.maleTypes.floor2x2.index,
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor2x2.index,
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.floor2x2.index,
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor2x2.index,
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
}

for x=-1,1 do
	for z = -1,1 do
		table.insert(malePoints.floor2x2MaleSnapPoints, {
			snapGroup = snapGroup.maleTypes.floor2x2Up.index,
			point = vec3(x, 0.0, z),
			normal = vec3(0.0, 0.0, 1.0),
		})
	end
end


malePoints.floorTri2MaleSnapPoints = {
	{
		snapGroup = snapGroup.maleTypes.floorTri2.index,
		point = vec3(0.0, 0.0, triFloor2m_inradius),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2.index,
		point = vec3xMat3(vec3(0.0, 0.0, triFloor2m_inradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixA),
	},
	{   
		snapGroup = snapGroup.maleTypes.floorTri2.index,
		point = vec3xMat3(vec3(0.0, 0.0, triFloor2m_inradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixB),
	},

	--[[{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, 0.0, 1.0),
	},

	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3(0.0, 0.0, triFloor2m_inradius),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3xMat3(vec3(0.0, 0.0, triFloor2m_inradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixA),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3xMat3(vec3(0.0, 0.0, triFloor2m_inradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, 1.0), triFloorRotMatrixB),
	},]]
	
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3(0.0, 0.0, -triFloor2m_circumradius),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixA),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixB),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3(0.0, 0.0, -triFloor2m_circumradius),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixA),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixA),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixA),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3(0.0, 0.0, -triFloor2m_circumradius),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixB),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixA),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixB),
	},
	{
		snapGroup = snapGroup.maleTypes.floorTri2Up.index,
		point = vec3xMat3(vec3(0.0, 0.0, -triFloor2m_circumradius), triFloorRotMatrixB),
		normal = vec3xMat3(vec3(0.0, 0.0, -1.0), triFloorRotMatrixB),
	},
}


malePoints.onFloor2x2MaleSnapPoints = {
	{
		snapGroup = snapGroup.maleTypes.onFloor2x2.index,
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.onFloor2x2.index,
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.onFloor2x2.index,
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.onFloor2x2.index,
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
}


malePoints.onFloor1x1MaleSnapPoints = {
	{
		snapGroup = snapGroup.maleTypes.onFloor1x1.index,
		point = vec3(-0.5, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.onFloor1x1.index,
		point = vec3(0.5, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.onFloor1x1.index,
		point = vec3(0.0, 0.0, -0.5),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.onFloor1x1.index,
		point = vec3(0.0, 0.0, 0.5),
		normal = vec3(0.0, 0.0, 1.0),
	},
}


malePoints.floor4x4MaleSnapPoints = {
	{
		snapGroup = snapGroup.maleTypes.floor4x4.index,
		point = vec3(-2.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4.index,
		point = vec3(2.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.floor4x4.index,
		point = vec3(0.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4.index,
		point = vec3(0.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4Quarter.index,
		point = vec3(-2.0, 0.0, 1.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4Quarter.index,
		point = vec3(-2.0, 0.0, -1.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4Quarter.index,
		point = vec3(2.0, 0.0, 1.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4Quarter.index,
		point = vec3(2.0, 0.0, -1.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.floor4x4Quarter.index,
		point = vec3(1.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{   
		snapGroup = snapGroup.maleTypes.floor4x4Quarter.index,
		point = vec3(-1.0, 0.0, -2.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4Quarter.index,
		point = vec3(1.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4Quarter.index,
		point = vec3(-1.0, 0.0, 2.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
	
	{
		snapGroup = snapGroup.maleTypes.floor4x4Center.index,
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4Center.index,
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4Center.index,
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.floor4x4Center.index,
		point = vec3(0.0, 0.0, -1.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
}

for x=-2,2 do
	for z = -2,2 do
		table.insert(malePoints.floor4x4MaleSnapPoints, {
			snapGroup = snapGroup.maleTypes.floor4x4Up.index,
			point = vec3(x, 0.0, z),
			normal = vec3(0.0, 0.0, 1.0),
		})
	end
end

malePoints.onFloor4x4MaleSnapPoints = malePoints.floor4x4MaleSnapPoints --WARNING if you're going to modify this, you will need to do a clone first


malePoints.steps1p5MaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.steps1p5Top.index,
		point = vec3(0.0, 2.0, -1.5),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.steps1p5Bottom.index,
		point = vec3(0.0, 0.0, 1.5),
		normal = vec3(0.0, 0.0, 1.0),
	},
}


malePoints.steps2HalfMaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.steps2HalfTop.index,
		point = vec3(0.0, 1.0, -1.0),
		normal = vec3(0.0, 0.0, -1.0),
	},
	{
		snapGroup = snapGroup.maleTypes.steps2HalfBottom.index,
		point = vec3(0.0, 0.0, 1.0),
		normal = vec3(0.0, 0.0, 1.0),
	},
}


malePoints.horizontalColumnMaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.column.index,
		point = vec3(1.0, 0.0, 0.0),
		normal = vec3(1.0, 0.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.column.index,
		point = vec3(-1.0, 0.0, 0.0),
		normal = vec3(-1.0, 0.0, 0.0),
	},
}
malePoints.verticalColumnMaleSnapPoints = {
	{   
		snapGroup = snapGroup.maleTypes.column.index,
		point = vec3(0.0, 2.0, 0.0),
		normal = vec3(0.0, 1.0, 0.0),
	},
	{
		snapGroup = snapGroup.maleTypes.column.index,
		point = vec3(0.0, 0.0, 0.0),
		normal = vec3(0.0, -1.0, 0.0),
	},
}

malePoints.shelfMaleSnapPoints = {
	{
		snapGroup = snapGroup.maleTypes.shelfBackCenter.index,
		point = vec3(0.0, 0.0, -0.2),
		normal = vec3(0.0, 0.0, -1.0),
	},
}

malePoints.toolRackMaleSnapPoints = {
	{
		snapGroup = snapGroup.maleTypes.toolRackBackCenter.index,
		point = vec3(0.0, 1.0, -0.2),
		normal = vec3(0.0, 0.0, -1.0),
	},
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(-1.0, 0.0, -0.3),
        normal = vec3(-1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.wallEdgeBottomX.index,
        point = vec3(1.0, 0.0, -0.3),
        normal = vec3(1.0, 0.0, 0.0),
    },
    {
        snapGroup = snapGroup.maleTypes.thinWallMiddleBottomZ.index,
        point = vec3(0.0, 0.0, -0.3),
        normal = vec3(0.0, 0.0, 1.0),
    },
}

for k,malePoint in pairs(malePoints) do
	local maleSnapGroupSet = {}
	malePoint.maleSnapGroupSet = maleSnapGroupSet
	for i,entry in ipairs(malePoint) do
		maleSnapGroupSet[entry.snapGroup] = true
	end
end

for k,femalePoint in pairs(femalePoints) do
	local allowedMaleSnapGroupSet = {}
	femalePoint.allowedMaleSnapGroupSet = allowedMaleSnapGroupSet
	for i,entry in ipairs(femalePoint) do
		entry.allowedMaleSnapGroupSet = {}
		for j,maleSnapGroup in ipairs(entry.maleSnapGroups) do
			allowedMaleSnapGroupSet[maleSnapGroup] = true
			entry.allowedMaleSnapGroupSet[maleSnapGroup] = true
		end
	end
end

return snapGroup