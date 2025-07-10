<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="3.44.0-Solothurn" minScale="100000000" hasScaleBasedVisibilityFlag="0" autoRefreshMode="Disabled" simplifyDrawingHints="0" maxScale="0" styleCategories="AllStyleCategories" simplifyMaxScale="1" symbologyReferenceScale="-1" autoRefreshTime="0" labelsEnabled="1" simplifyAlgorithm="0" simplifyDrawingTol="1" readOnly="0" simplifyLocal="1">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
    <Private>0</Private>
  </flags>
  <temporal durationField="ogc_fid" durationUnit="min" endExpression="" fixedDuration="0" enabled="0" mode="0" accumulate="0" startExpression="" limitMode="0" startField="date_visit" endField="">
    <fixedRange>
      <start></start>
      <end></end>
    </fixedRange>
  </temporal>
  <elevation extrusion="0" showMarkerSymbolInSurfacePlots="0" binding="Centroid" respectLayerSymbol="1" zoffset="0" extrusionEnabled="0" type="IndividualFeatures" symbology="Line" customToleranceEnabled="0" zscale="1" clamping="Terrain">
    <data-defined-properties>
      <Option type="Map">
        <Option type="QString" value="" name="name"/>
        <Option name="properties"/>
        <Option type="QString" value="collection" name="type"/>
      </Option>
    </data-defined-properties>
    <profileLineSymbol>
      <symbol frame_rate="10" force_rhr="0" type="line" is_animated="0" clip_to_extent="1" name="" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" id="{0fdd78fa-33d9-408b-bb74-b6b5c6da6a40}" class="SimpleLine" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="114,155,111,255,rgb:0.4470588,0.6078431,0.4352941,1" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.6" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </profileLineSymbol>
    <profileFillSymbol>
      <symbol frame_rate="10" force_rhr="0" type="fill" is_animated="0" clip_to_extent="1" name="" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" id="{9e1608b8-7b03-4713-93de-ec74215dc064}" class="SimpleFill" locked="0">
          <Option type="Map">
            <Option type="QString" value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale"/>
            <Option type="QString" value="114,155,111,255,rgb:0.4470588,0.6078431,0.4352941,1" name="color"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="81,111,79,255,rgb:0.3193256,0.434165,0.3109178,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0.2" name="outline_width"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="solid" name="style"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </profileFillSymbol>
    <profileMarkerSymbol>
      <symbol frame_rate="10" force_rhr="0" type="marker" is_animated="0" clip_to_extent="1" name="" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" id="{2f4f3881-5f21-4901-a755-09f90e4d87c5}" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="114,155,111,255,rgb:0.4470588,0.6078431,0.4352941,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="diamond" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="81,111,79,255,rgb:0.3193256,0.434165,0.3109178,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0.2" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="diameter" name="scale_method"/>
            <Option type="QString" value="3" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </profileMarkerSymbol>
  </elevation>
  <renderer-v2 referencescale="-1" enableorderby="0" type="categorizedSymbol" forceraster="0" attr="CASE WHEN &quot;is_scheduled&quot; THEN&#xa;  CASE WHEN &quot;visit_done&quot; THEN 'scheduled+done' &#xa;  ELSE 'scheduled' END&#xa;ELSE &#xa;  CASE WHEN &quot;visit_done&quot; THEN 'done' &#xa;  ELSE 'not scheduled' END&#xa;END" symbollevels="0">
    <categories>
      <category type="string" label="(niet gepland)" value="" render="true" uuid="{051df933-7412-4efe-9cd2-4721e6133666}" symbol="0"/>
      <category type="string" label="gepland" value="scheduled" render="true" uuid="{7f1fc55c-3f45-47ea-94ff-768dad3abc40}" symbol="1"/>
      <category type="string" label="ongepland gedaan" value="done" render="true" uuid="{7fced544-37cf-4f69-b30e-ed0ca81a375a}" symbol="2"/>
      <category type="string" label="gepland en uitgevoerd" value="scheduled+done" render="true" uuid="{ab151e80-3d07-4ceb-a861-48352c561d74}" symbol="3"/>
    </categories>
    <symbols>
      <symbol frame_rate="10" force_rhr="0" type="marker" is_animated="0" clip_to_extent="1" name="0" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" id="{b0c9ff1b-6463-43ea-8032-9705fe388402}" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="144,144,144,255,hsv:0.86111111111111116,0,0.562905317769131,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="circle" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="diameter" name="scale_method"/>
            <Option type="QString" value="1.5" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol frame_rate="10" force_rhr="0" type="marker" is_animated="0" clip_to_extent="1" name="1" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" id="{54ad6789-a45c-4e64-a289-3796caf2096c}" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="255,185,0,255,hsv:0.12111111111111111,1,1,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="circle" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="diameter" name="scale_method"/>
            <Option type="QString" value="3" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol frame_rate="10" force_rhr="0" type="marker" is_animated="0" clip_to_extent="1" name="2" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" id="{dbcbcb53-33a4-4450-ab64-d14011081d4d}" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="45,210,156,255,hsv:0.44522222222222224,0.78315403982604714,0.82241550316624701,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="circle" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="diameter" name="scale_method"/>
            <Option type="QString" value="2" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
      <symbol frame_rate="10" force_rhr="0" type="marker" is_animated="0" clip_to_extent="1" name="3" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" id="{3f9b6676-0ff0-43df-9de8-a28b1f71a764}" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="0,138,83,255,hsv:0.43302777777777779,1,0.54285496299687186,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="circle" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="diameter" name="scale_method"/>
            <Option type="QString" value="2" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <source-symbol>
      <symbol frame_rate="10" force_rhr="0" type="marker" is_animated="0" clip_to_extent="1" name="0" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" id="{cf5d1173-37f4-4da2-a64a-ce2b3183a3eb}" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="255,173,0,255,hsv:0.11336111111111111,1,1,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="circle" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="diameter" name="scale_method"/>
            <Option type="QString" value="2" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </source-symbol>
    <rotation/>
    <sizescale/>
    <data-defined-properties>
      <Option type="Map">
        <Option type="QString" value="" name="name"/>
        <Option name="properties"/>
        <Option type="QString" value="collection" name="type"/>
      </Option>
    </data-defined-properties>
  </renderer-v2>
  <selection mode="Default">
    <selectionColor invalid="1"/>
    <selectionSymbol>
      <symbol frame_rate="10" force_rhr="0" type="marker" is_animated="0" clip_to_extent="1" name="" alpha="1">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer pass="0" enabled="1" id="{a4f81c4e-f9ce-44ed-b335-987471db2de9}" class="SimpleMarker" locked="0">
          <Option type="Map">
            <Option type="QString" value="0" name="angle"/>
            <Option type="QString" value="square" name="cap_style"/>
            <Option type="QString" value="255,0,0,255,rgb:1,0,0,1" name="color"/>
            <Option type="QString" value="1" name="horizontal_anchor_point"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="circle" name="name"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1" name="outline_color"/>
            <Option type="QString" value="solid" name="outline_style"/>
            <Option type="QString" value="0" name="outline_width"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="diameter" name="scale_method"/>
            <Option type="QString" value="2" name="size"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
            <Option type="QString" value="MM" name="size_unit"/>
            <Option type="QString" value="1" name="vertical_anchor_point"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </selectionSymbol>
  </selection>
  <labeling type="simple">
    <settings calloutType="simple">
      <text-style fontWordSpacing="0" isExpression="1" forcedItalic="0" multilineHeight="1" tabStopDistanceMapUnitScale="3x:0,0,0,0,0,0" tabStopDistanceUnit="Point" tabStopDistance="80" fontUnderline="0" fontSizeMapUnitScale="3x:0,0,0,0,0,0" stretchFactor="100" blendMode="0" fontWeight="50" fontFamily="Open Sans" previewBkgrdColor="255,255,255,255,rgb:1,1,1,1" fontSizeUnit="Point" fontItalic="0" multilineHeightUnit="Percentage" textOpacity="1" fontKerning="1" legendString="Aa" forcedBold="0" useSubstitutions="0" fontStrikeout="0" namedStyle="Regular" fontLetterSpacing="0" capitalization="0" textOrientation="horizontal" fontSize="10" fieldName="represent_value( &quot;activity_group_id&quot; )" textColor="50,50,50,255,rgb:0.1960784,0.1960784,0.1960784,1" allowHtml="0">
        <families/>
        <text-buffer bufferOpacity="1" bufferSizeMapUnitScale="3x:0,0,0,0,0,0" bufferJoinStyle="128" bufferSize="1" bufferNoFill="1" bufferSizeUnits="MM" bufferDraw="0" bufferColor="250,250,250,255,rgb:0.9803922,0.9803922,0.9803922,1" bufferBlendMode="0"/>
        <text-mask maskSize="1.5" maskSize2="1.5" maskedSymbolLayers="" maskSizeMapUnitScale="3x:0,0,0,0,0,0" maskJoinStyle="128" maskEnabled="0" maskSizeUnits="MM" maskType="0" maskOpacity="1"/>
        <background shapeOffsetUnit="Point" shapeRotation="0" shapeRadiiY="0" shapeOffsetX="0" shapeBorderWidth="0" shapeRotationType="0" shapeBorderColor="128,128,128,255,rgb:0.5019608,0.5019608,0.5019608,1" shapeSizeUnit="Point" shapeType="0" shapeSizeMapUnitScale="3x:0,0,0,0,0,0" shapeSizeX="0" shapeBorderWidthUnit="Point" shapeOffsetMapUnitScale="3x:0,0,0,0,0,0" shapeSizeType="0" shapeBlendMode="0" shapeJoinStyle="64" shapeOpacity="1" shapeRadiiUnit="Point" shapeRadiiMapUnitScale="3x:0,0,0,0,0,0" shapeSizeY="0" shapeDraw="0" shapeFillColor="255,255,255,255,rgb:1,1,1,1" shapeBorderWidthMapUnitScale="3x:0,0,0,0,0,0" shapeRadiiX="0" shapeSVGFile="" shapeOffsetY="0">
          <symbol frame_rate="10" force_rhr="0" type="marker" is_animated="0" clip_to_extent="1" name="markerSymbol" alpha="1">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer pass="0" enabled="1" id="" class="SimpleMarker" locked="0">
              <Option type="Map">
                <Option type="QString" value="0" name="angle"/>
                <Option type="QString" value="square" name="cap_style"/>
                <Option type="QString" value="255,158,23,255,rgb:1,0.6196078,0.0901961,1" name="color"/>
                <Option type="QString" value="1" name="horizontal_anchor_point"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="circle" name="name"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="35,35,35,255,rgb:0.1372549,0.1372549,0.1372549,1" name="outline_color"/>
                <Option type="QString" value="solid" name="outline_style"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="outline_width_map_unit_scale"/>
                <Option type="QString" value="MM" name="outline_width_unit"/>
                <Option type="QString" value="diameter" name="scale_method"/>
                <Option type="QString" value="2" name="size"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="size_map_unit_scale"/>
                <Option type="QString" value="MM" name="size_unit"/>
                <Option type="QString" value="1" name="vertical_anchor_point"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" value="" name="name"/>
                  <Option name="properties"/>
                  <Option type="QString" value="collection" name="type"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
          <symbol frame_rate="10" force_rhr="0" type="fill" is_animated="0" clip_to_extent="1" name="fillSymbol" alpha="1">
            <data_defined_properties>
              <Option type="Map">
                <Option type="QString" value="" name="name"/>
                <Option name="properties"/>
                <Option type="QString" value="collection" name="type"/>
              </Option>
            </data_defined_properties>
            <layer pass="0" enabled="1" id="" class="SimpleFill" locked="0">
              <Option type="Map">
                <Option type="QString" value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale"/>
                <Option type="QString" value="255,255,255,255,rgb:1,1,1,1" name="color"/>
                <Option type="QString" value="bevel" name="joinstyle"/>
                <Option type="QString" value="0,0" name="offset"/>
                <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
                <Option type="QString" value="MM" name="offset_unit"/>
                <Option type="QString" value="128,128,128,255,rgb:0.5019608,0.5019608,0.5019608,1" name="outline_color"/>
                <Option type="QString" value="no" name="outline_style"/>
                <Option type="QString" value="0" name="outline_width"/>
                <Option type="QString" value="Point" name="outline_width_unit"/>
                <Option type="QString" value="solid" name="style"/>
              </Option>
              <data_defined_properties>
                <Option type="Map">
                  <Option type="QString" value="" name="name"/>
                  <Option name="properties"/>
                  <Option type="QString" value="collection" name="type"/>
                </Option>
              </data_defined_properties>
            </layer>
          </symbol>
        </background>
        <shadow shadowOffsetUnit="MM" shadowRadiusAlphaOnly="0" shadowUnder="0" shadowScale="100" shadowColor="0,0,0,255,rgb:0,0,0,1" shadowOffsetDist="1" shadowOffsetGlobal="1" shadowOffsetAngle="135" shadowRadiusUnit="MM" shadowOpacity="0.69999999999999996" shadowBlendMode="6" shadowDraw="0" shadowOffsetMapUnitScale="3x:0,0,0,0,0,0" shadowRadius="1.5" shadowRadiusMapUnitScale="3x:0,0,0,0,0,0"/>
        <dd_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </dd_properties>
        <substitutions/>
      </text-style>
      <text-format addDirectionSymbol="0" useMaxLineLengthForAutoWrap="1" plussign="0" leftDirectionSymbol="&lt;" autoWrapLength="0" rightDirectionSymbol=">" wrapChar="" multilineAlign="3" decimals="3" formatNumbers="0" placeDirectionSymbol="0" reverseDirectionSymbol="0"/>
      <placement rotationAngle="0" distMapUnitScale="3x:0,0,0,0,0,0" geometryGeneratorEnabled="0" overrunDistance="0" priority="5" dist="0" allowDegraded="0" xOffset="0" distUnits="MM" repeatDistanceMapUnitScale="3x:0,0,0,0,0,0" maxCurvedCharAngleOut="-25" quadOffset="4" yOffset="0" polygonPlacementFlags="2" offsetUnits="MM" preserveRotation="1" overrunDistanceUnit="MM" prioritization="PreferCloser" layerType="PointGeometry" overrunDistanceMapUnitScale="3x:0,0,0,0,0,0" predefinedPositionOrder="TR,TL,BR,BL,R,L,TSR,BSR" centroidInside="0" placement="6" lineAnchorTextPoint="FollowPlacement" labelOffsetMapUnitScale="3x:0,0,0,0,0,0" lineAnchorType="0" maximumDistanceMapUnitScale="3x:0,0,0,0,0,0" repeatDistanceUnits="MM" maximumDistance="0" fitInPolygonOnly="0" repeatDistance="0" maximumDistanceUnit="MM" placementFlags="10" geometryGeneratorType="PointGeometry" lineAnchorClipping="0" centroidWhole="0" maxCurvedCharAngleIn="25" geometryGenerator="" overlapHandling="PreventOverlap" lineAnchorPercent="0.5" offsetType="1" rotationUnit="AngleDegrees"/>
      <rendering minFeatureSize="0" mergeLines="0" fontMinPixelSize="3" scaleMax="0" fontMaxPixelSize="10000" scaleMin="0" obstacleType="1" limitNumLabels="0" drawLabels="1" obstacle="1" upsidedownLabels="0" labelPerPart="0" zIndex="0" maxNumLabels="2000" obstacleFactor="1" scaleVisibility="0" fontLimitPixelSize="0" unplacedVisibility="0"/>
      <dd_properties>
        <Option type="Map">
          <Option type="QString" value="" name="name"/>
          <Option name="properties"/>
          <Option type="QString" value="collection" name="type"/>
        </Option>
      </dd_properties>
      <callout type="simple">
        <Option type="Map">
          <Option type="QString" value="pole_of_inaccessibility" name="anchorPoint"/>
          <Option type="int" value="0" name="blendMode"/>
          <Option type="Map" name="ddProperties">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
          <Option type="bool" value="false" name="drawToAllParts"/>
          <Option type="QString" value="0" name="enabled"/>
          <Option type="QString" value="point_on_exterior" name="labelAnchorPoint"/>
          <Option type="QString" value="&lt;symbol frame_rate=&quot;10&quot; force_rhr=&quot;0&quot; type=&quot;line&quot; is_animated=&quot;0&quot; clip_to_extent=&quot;1&quot; name=&quot;symbol&quot; alpha=&quot;1&quot;>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;layer pass=&quot;0&quot; enabled=&quot;1&quot; id=&quot;{b83d9fef-3120-4b8b-bcc0-d09071165c54}&quot; class=&quot;SimpleLine&quot; locked=&quot;0&quot;>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;align_dash_pattern&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;square&quot; name=&quot;capstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;5;2&quot; name=&quot;customdash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;customdash_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;customdash_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;dash_pattern_offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;dash_pattern_offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;dash_pattern_offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;draw_inside_polygon&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;bevel&quot; name=&quot;joinstyle&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;60,60,60,255,rgb:0.2352941,0.2352941,0.2352941,1&quot; name=&quot;line_color&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;solid&quot; name=&quot;line_style&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0.3&quot; name=&quot;line_width&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;line_width_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;offset&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;offset_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;offset_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;ring_filter&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_end&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_end_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_end_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;trim_distance_start&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;trim_distance_start_map_unit_scale&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;MM&quot; name=&quot;trim_distance_start_unit&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;tweak_dash_pattern_on_corners&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;0&quot; name=&quot;use_custom_dash&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;3x:0,0,0,0,0,0&quot; name=&quot;width_map_unit_scale&quot;/>&lt;/Option>&lt;data_defined_properties>&lt;Option type=&quot;Map&quot;>&lt;Option type=&quot;QString&quot; value=&quot;&quot; name=&quot;name&quot;/>&lt;Option name=&quot;properties&quot;/>&lt;Option type=&quot;QString&quot; value=&quot;collection&quot; name=&quot;type&quot;/>&lt;/Option>&lt;/data_defined_properties>&lt;/layer>&lt;/symbol>" name="lineSymbol"/>
          <Option type="double" value="0" name="minLength"/>
          <Option type="QString" value="3x:0,0,0,0,0,0" name="minLengthMapUnitScale"/>
          <Option type="QString" value="MM" name="minLengthUnit"/>
          <Option type="double" value="0" name="offsetFromAnchor"/>
          <Option type="QString" value="3x:0,0,0,0,0,0" name="offsetFromAnchorMapUnitScale"/>
          <Option type="QString" value="MM" name="offsetFromAnchorUnit"/>
          <Option type="double" value="0" name="offsetFromLabel"/>
          <Option type="QString" value="3x:0,0,0,0,0,0" name="offsetFromLabelMapUnitScale"/>
          <Option type="QString" value="MM" name="offsetFromLabelUnit"/>
        </Option>
      </callout>
    </settings>
  </labeling>
  <customproperties>
    <Option type="Map">
      <Option type="QString" value="no_action" name="QFieldSync/action"/>
      <Option type="QString" value="{&quot;photo&quot;: &quot;'DCIM/loceval_' || format_date(now(),'yyyyMMddhhmmsszzz') || '.{extension}'&quot;}" name="QFieldSync/attachment_naming"/>
      <Option type="QString" value="no_action" name="QFieldSync/cloud_action"/>
      <Option type="invalid" name="QFieldSync/geometry_locked_expression"/>
      <Option type="bool" value="true" name="QFieldSync/is_geometry_locked"/>
      <Option type="QString" value="{&quot;photo&quot;: &quot;'DCIM/loceval_' || format_date(now(),'yyyyMMddhhmmsszzz') || '.{extension}'&quot;}" name="QFieldSync/photo_naming"/>
      <Option type="QString" value="{}" name="QFieldSync/relationship_maximum_visible"/>
      <Option type="int" value="30" name="QFieldSync/tracking_distance_requirement_minimum_meters"/>
      <Option type="int" value="1" name="QFieldSync/tracking_erroneous_distance_safeguard_maximum_meters"/>
      <Option type="int" value="0" name="QFieldSync/tracking_measurement_type"/>
      <Option type="int" value="30" name="QFieldSync/tracking_time_requirement_interval_seconds"/>
      <Option type="int" value="0" name="QFieldSync/value_map_button_interface_threshold"/>
      <Option type="int" value="0" name="embeddedWidgets/count"/>
      <Option name="variableNames"/>
      <Option name="variableValues"/>
    </Option>
  </customproperties>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerOpacity>0.6</layerOpacity>
  <geometryOptions geometryPrecision="0" removeDuplicateNodes="0">
    <activeChecks/>
    <checkConfiguration/>
  </geometryOptions>
  <legend type="default-vector" showLabelLegend="0"/>
  <referencedLayers/>
  <fieldConfiguration>
    <field name="ogc_fid" configurationFlags="NoFlag">
      <editWidget type="Range">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2147483647" name="Max"/>
            <Option type="int" value="-2147483648" name="Min"/>
            <Option type="int" value="0" name="Precision"/>
            <Option type="int" value="1" name="Step"/>
            <Option type="QString" value="SpinBox" name="Style"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="location_id" configurationFlags="NoFlag">
      <editWidget type="Range">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2147483647" name="Max"/>
            <Option type="int" value="-2147483648" name="Min"/>
            <Option type="int" value="0" name="Precision"/>
            <Option type="int" value="1" name="Step"/>
            <Option type="QString" value="SpinBox" name="Style"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="grts_address" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="extravisit_id" configurationFlags="NoFlag">
      <editWidget type="Range">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2147483647" name="Max"/>
            <Option type="int" value="-2147483648" name="Min"/>
            <Option type="int" value="0" name="Precision"/>
            <Option type="int" value="1" name="Step"/>
            <Option type="QString" value="SpinBox" name="Style"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="teammember_id" configurationFlags="NoFlag">
      <editWidget type="ValueRelation">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="AllowMulti"/>
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2" name="CompleterMatchFlags"/>
            <Option type="invalid" name="Description"/>
            <Option type="bool" value="false" name="DisplayGroupName"/>
            <Option type="invalid" name="FilterExpression"/>
            <Option type="invalid" name="Group"/>
            <Option type="QString" value="teammember_id" name="Key"/>
            <Option type="QString" value="TeamMembers_ac94148e_85d0_4d02_97bd_30519ef49f7f" name="Layer"/>
            <Option type="QString" value="TeamMembers" name="LayerName"/>
            <Option type="QString" value="postgres" name="LayerProviderName"/>
            <Option type="QString" value="dbname='loceval' host=172.233.44.119 port=2407 sslmode=disable authcfg=9wwr376 key='teammember_id' checkPrimaryKeyUnicity='0' table=&quot;metadata&quot;.&quot;TeamMembers&quot;" name="LayerSource"/>
            <Option type="int" value="1" name="NofColumns"/>
            <Option type="bool" value="false" name="OrderByDescending"/>
            <Option type="bool" value="false" name="OrderByField"/>
            <Option type="QString" value="teammember_id" name="OrderByFieldName"/>
            <Option type="bool" value="true" name="OrderByKey"/>
            <Option type="bool" value="false" name="OrderByValue"/>
            <Option type="bool" value="false" name="UseCompleter"/>
            <Option type="QString" value="username" name="Value"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="date_visit" configurationFlags="NoFlag">
      <editWidget type="DateTime">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="allow_null"/>
            <Option type="bool" value="true" name="calendar_popup"/>
            <Option type="QString" value="yyyy-MM-dd" name="display_format"/>
            <Option type="QString" value="yyyy-MM-dd" name="field_format"/>
            <Option type="bool" value="false" name="field_format_overwrite"/>
            <Option type="bool" value="false" name="field_iso_format"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="type_assessed" configurationFlags="NoFlag">
      <editWidget type="ValueRelation">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="AllowMulti"/>
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2" name="CompleterMatchFlags"/>
            <Option type="invalid" name="Description"/>
            <Option type="bool" value="false" name="DisplayGroupName"/>
            <Option type="invalid" name="FilterExpression"/>
            <Option type="invalid" name="Group"/>
            <Option type="QString" value="type" name="Key"/>
            <Option type="QString" value="N2kHabTypes_17f1db33_9953_4338_b778_ceaaf2f0e6b8" name="Layer"/>
            <Option type="QString" value="N2kHabTypes" name="LayerName"/>
            <Option type="QString" value="postgres" name="LayerProviderName"/>
            <Option type="QString" value="dbname='loceval' host=172.233.44.119 port=2407 sslmode=disable authcfg=9wwr376 key='n2khabtype_id' checkPrimaryKeyUnicity='0' table=&quot;metadata&quot;.&quot;N2kHabTypes&quot;" name="LayerSource"/>
            <Option type="int" value="1" name="NofColumns"/>
            <Option type="bool" value="false" name="OrderByDescending"/>
            <Option type="bool" value="false" name="OrderByField"/>
            <Option type="QString" value="n2khabtype_id" name="OrderByFieldName"/>
            <Option type="bool" value="true" name="OrderByKey"/>
            <Option type="bool" value="false" name="OrderByValue"/>
            <Option type="bool" value="false" name="UseCompleter"/>
            <Option type="QString" value="type" name="Value"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="notes" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="photo" configurationFlags="NoFlag">
      <editWidget type="ExternalResource">
        <config>
          <Option type="Map">
            <Option type="QString" value="DCIM" name="DefaultRoot"/>
            <Option type="int" value="1" name="DocumentViewer"/>
            <Option type="int" value="0" name="DocumentViewerHeight"/>
            <Option type="int" value="0" name="DocumentViewerWidth"/>
            <Option type="bool" value="true" name="FileWidget"/>
            <Option type="bool" value="true" name="FileWidgetButton"/>
            <Option type="invalid" name="FileWidgetFilter"/>
            <Option type="Map" name="PropertyCollection">
              <Option type="invalid" name="name"/>
              <Option type="invalid" name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
            <Option type="int" value="1" name="RelativeStorage"/>
            <Option type="invalid" name="StorageAuthConfigId"/>
            <Option type="int" value="0" name="StorageMode"/>
            <Option type="invalid" name="StorageType"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="visit_done" configurationFlags="NoFlag">
      <editWidget type="CheckBox">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="AllowNullState"/>
            <Option type="invalid" name="CheckedState"/>
            <Option type="int" value="0" name="TextDisplayMethod"/>
            <Option type="invalid" name="UncheckedState"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="samplelocation_id" configurationFlags="NoFlag">
      <editWidget type="Range">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2147483647" name="Max"/>
            <Option type="int" value="-2147483648" name="Min"/>
            <Option type="int" value="0" name="Precision"/>
            <Option type="int" value="1" name="Step"/>
            <Option type="QString" value="SpinBox" name="Style"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="grts_join_method" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="scheme" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="panel_set" configurationFlags="NoFlag">
      <editWidget type="Range">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2147483647" name="Max"/>
            <Option type="int" value="-2147483648" name="Min"/>
            <Option type="int" value="0" name="Precision"/>
            <Option type="int" value="1" name="Step"/>
            <Option type="QString" value="SpinBox" name="Style"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="targetpanel" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="scheme_ps_targetpanels" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="sp_poststratum" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="type" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="assessment" configurationFlags="NoFlag">
      <editWidget type="CheckBox">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="AllowNullState"/>
            <Option type="invalid" name="CheckedState"/>
            <Option type="int" value="0" name="TextDisplayMethod"/>
            <Option type="invalid" name="UncheckedState"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="assessment_date" configurationFlags="NoFlag">
      <editWidget type="DateTime">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="allow_null"/>
            <Option type="bool" value="true" name="calendar_popup"/>
            <Option type="QString" value="yyyy-MM-dd" name="display_format"/>
            <Option type="QString" value="yyyy-MM-dd" name="field_format"/>
            <Option type="bool" value="false" name="field_format_overwrite"/>
            <Option type="bool" value="false" name="field_iso_format"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="is_replaced" configurationFlags="NoFlag">
      <editWidget type="CheckBox">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="AllowNullState"/>
            <Option type="invalid" name="CheckedState"/>
            <Option type="int" value="0" name="TextDisplayMethod"/>
            <Option type="invalid" name="UncheckedState"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="replacement_ongoing" configurationFlags="NoFlag">
      <editWidget type="CheckBox">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="AllowNullState"/>
            <Option type="invalid" name="CheckedState"/>
            <Option type="int" value="0" name="TextDisplayMethod"/>
            <Option type="invalid" name="UncheckedState"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="replacement_reason" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="replacement_permanence" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="assessment_done" configurationFlags="NoFlag">
      <editWidget type="CheckBox">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="cell_disapproved" configurationFlags="NoFlag">
      <editWidget type="CheckBox">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="AllowNullState"/>
            <Option type="invalid" name="CheckedState"/>
            <Option type="int" value="0" name="TextDisplayMethod"/>
            <Option type="invalid" name="UncheckedState"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="location_assessment" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="is_scheduled" configurationFlags="NoFlag">
      <editWidget type="CheckBox">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="AllowNullState"/>
            <Option type="invalid" name="CheckedState"/>
            <Option type="int" value="0" name="TextDisplayMethod"/>
            <Option type="invalid" name="UncheckedState"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="teammember_assigned" configurationFlags="NoFlag">
      <editWidget type="Range">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2147483647" name="Max"/>
            <Option type="int" value="-2147483648" name="Min"/>
            <Option type="int" value="0" name="Precision"/>
            <Option type="int" value="1" name="Step"/>
            <Option type="QString" value="SpinBox" name="Style"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="activity_group_id" configurationFlags="NoFlag">
      <editWidget type="ValueRelation">
        <config>
          <Option type="Map">
            <Option type="bool" value="false" name="AllowMulti"/>
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2" name="CompleterMatchFlags"/>
            <Option type="invalid" name="Description"/>
            <Option type="bool" value="false" name="DisplayGroupName"/>
            <Option type="invalid" name="FilterExpression"/>
            <Option type="QString" value="activity_group" name="Group"/>
            <Option type="QString" value="activity_group_id" name="Key"/>
            <Option type="QString" value="GroupedActivities_3a123066_4e77_4433_8772_2ad9c3538040" name="Layer"/>
            <Option type="QString" value="GroupedActivities" name="LayerName"/>
            <Option type="QString" value="postgres" name="LayerProviderName"/>
            <Option type="QString" value="dbname='loceval' host=172.233.44.119 port=2407 sslmode=disable authcfg=9wwr376 key='grouped_activity_id' checkPrimaryKeyUnicity='0' table=&quot;metadata&quot;.&quot;GroupedActivities&quot;" name="LayerSource"/>
            <Option type="int" value="1" name="NofColumns"/>
            <Option type="bool" value="false" name="OrderByDescending"/>
            <Option type="bool" value="false" name="OrderByField"/>
            <Option type="QString" value="grouped_activity_id" name="OrderByFieldName"/>
            <Option type="bool" value="true" name="OrderByKey"/>
            <Option type="bool" value="false" name="OrderByValue"/>
            <Option type="bool" value="false" name="UseCompleter"/>
            <Option type="QString" value="activity_group" name="Value"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="date_visit_planned" configurationFlags="NoFlag">
      <editWidget type="DateTime">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="allow_null"/>
            <Option type="bool" value="true" name="calendar_popup"/>
            <Option type="QString" value="yyyy-MM-dd" name="display_format"/>
            <Option type="QString" value="yyyy-MM-dd" name="field_format"/>
            <Option type="bool" value="false" name="field_format_overwrite"/>
            <Option type="bool" value="false" name="field_iso_format"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="days_to_visit" configurationFlags="NoFlag">
      <editWidget type="Range">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="AllowNull"/>
            <Option type="int" value="2147483647" name="Max"/>
            <Option type="int" value="-2147483648" name="Min"/>
            <Option type="int" value="0" name="Precision"/>
            <Option type="int" value="1" name="Step"/>
            <Option type="QString" value="SpinBox" name="Style"/>
          </Option>
        </config>
      </editWidget>
    </field>
    <field name="days_to_deadline" configurationFlags="NoFlag">
      <editWidget type="Range">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="priority" configurationFlags="NoFlag">
      <editWidget type="Range">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="preparation_notes" configurationFlags="NoFlag">
      <editWidget type="TextEdit">
        <config>
          <Option type="Map">
            <Option type="bool" value="true" name="IsMultiline"/>
            <Option type="bool" value="false" name="UseHtml"/>
          </Option>
        </config>
      </editWidget>
    </field>
  </fieldConfiguration>
  <aliases>
    <alias index="0" field="ogc_fid" name=""/>
    <alias index="1" field="location_id" name=""/>
    <alias index="2" field="grts_address" name="GRTS"/>
    <alias index="3" field="extravisit_id" name=""/>
    <alias index="4" field="teammember_id" name="teamlid uitvoering"/>
    <alias index="5" field="date_visit" name="datum bezoek"/>
    <alias index="6" field="type_assessed" name="type"/>
    <alias index="7" field="notes" name="notities"/>
    <alias index="8" field="photo" name="foto"/>
    <alias index="9" field="visit_done" name="bezoek gedaan"/>
    <alias index="10" field="samplelocation_id" name=""/>
    <alias index="11" field="grts_join_method" name=""/>
    <alias index="12" field="scheme" name=""/>
    <alias index="13" field="panel_set" name=""/>
    <alias index="14" field="targetpanel" name=""/>
    <alias index="15" field="scheme_ps_targetpanels" name=""/>
    <alias index="16" field="sp_poststratum" name=""/>
    <alias index="17" field="type" name=""/>
    <alias index="18" field="assessment" name="inschatting biodiv"/>
    <alias index="19" field="assessment_date" name="datum inschatting biodiv"/>
    <alias index="20" field="is_replaced" name="vervanging gedaan"/>
    <alias index="21" field="replacement_ongoing" name="lokale vervanging nodig"/>
    <alias index="22" field="replacement_reason" name="reden voor vervanging"/>
    <alias index="23" field="replacement_permanence" name="vervanging permanent?"/>
    <alias index="24" field="assessment_done" name=""/>
    <alias index="25" field="cell_disapproved" name="cel afgekeurd obv orthofoto's"/>
    <alias index="26" field="location_assessment" name="ofo assessment"/>
    <alias index="27" field="is_scheduled" name=""/>
    <alias index="28" field="teammember_assigned" name="toegewezen teamlid"/>
    <alias index="29" field="activity_group_id" name="activiteitsgroep"/>
    <alias index="30" field="date_visit_planned" name="geplande bezoekdatum"/>
    <alias index="31" field="days_to_visit" name="daten verblijvend tot bezoek"/>
    <alias index="32" field="days_to_deadline" name=""/>
    <alias index="33" field="priority" name=""/>
    <alias index="34" field="preparation_notes" name="notities voorbereiding"/>
  </aliases>
  <splitPolicies>
    <policy policy="DefaultValue" field="ogc_fid"/>
    <policy policy="DefaultValue" field="location_id"/>
    <policy policy="DefaultValue" field="grts_address"/>
    <policy policy="DefaultValue" field="extravisit_id"/>
    <policy policy="DefaultValue" field="teammember_id"/>
    <policy policy="DefaultValue" field="date_visit"/>
    <policy policy="DefaultValue" field="type_assessed"/>
    <policy policy="DefaultValue" field="notes"/>
    <policy policy="DefaultValue" field="photo"/>
    <policy policy="DefaultValue" field="visit_done"/>
    <policy policy="DefaultValue" field="samplelocation_id"/>
    <policy policy="DefaultValue" field="grts_join_method"/>
    <policy policy="DefaultValue" field="scheme"/>
    <policy policy="DefaultValue" field="panel_set"/>
    <policy policy="DefaultValue" field="targetpanel"/>
    <policy policy="DefaultValue" field="scheme_ps_targetpanels"/>
    <policy policy="DefaultValue" field="sp_poststratum"/>
    <policy policy="DefaultValue" field="type"/>
    <policy policy="DefaultValue" field="assessment"/>
    <policy policy="DefaultValue" field="assessment_date"/>
    <policy policy="DefaultValue" field="is_replaced"/>
    <policy policy="DefaultValue" field="replacement_ongoing"/>
    <policy policy="DefaultValue" field="replacement_reason"/>
    <policy policy="DefaultValue" field="replacement_permanence"/>
    <policy policy="DefaultValue" field="cell_disapproved"/>
    <policy policy="DefaultValue" field="location_assessment"/>
    <policy policy="DefaultValue" field="is_scheduled"/>
    <policy policy="DefaultValue" field="teammember_assigned"/>
    <policy policy="DefaultValue" field="activity_group_id"/>
    <policy policy="DefaultValue" field="date_visit_planned"/>
    <policy policy="DefaultValue" field="days_to_visit"/>
    <policy policy="DefaultValue" field="preparation_notes"/>
  </splitPolicies>
  <defaults>
    <default field="ogc_fid" applyOnUpdate="0" expression=""/>
    <default field="location_id" applyOnUpdate="0" expression=""/>
    <default field="grts_address" applyOnUpdate="0" expression=""/>
    <default field="extravisit_id" applyOnUpdate="0" expression=""/>
    <default field="teammember_id" applyOnUpdate="0" expression=""/>
    <default field="date_visit" applyOnUpdate="0" expression=""/>
    <default field="type_assessed" applyOnUpdate="0" expression=""/>
    <default field="notes" applyOnUpdate="0" expression=""/>
    <default field="photo" applyOnUpdate="0" expression=""/>
    <default field="visit_done" applyOnUpdate="0" expression=""/>
    <default field="samplelocation_id" applyOnUpdate="0" expression=""/>
    <default field="grts_join_method" applyOnUpdate="0" expression=""/>
    <default field="scheme" applyOnUpdate="0" expression=""/>
    <default field="panel_set" applyOnUpdate="0" expression=""/>
    <default field="targetpanel" applyOnUpdate="0" expression=""/>
    <default field="scheme_ps_targetpanels" applyOnUpdate="0" expression=""/>
    <default field="sp_poststratum" applyOnUpdate="0" expression=""/>
    <default field="type" applyOnUpdate="0" expression=""/>
    <default field="assessment" applyOnUpdate="0" expression=""/>
    <default field="assessment_date" applyOnUpdate="0" expression=""/>
    <default field="is_replaced" applyOnUpdate="0" expression=""/>
    <default field="replacement_ongoing" applyOnUpdate="0" expression=""/>
    <default field="replacement_reason" applyOnUpdate="0" expression=""/>
    <default field="replacement_permanence" applyOnUpdate="0" expression=""/>
    <default field="assessment_done" applyOnUpdate="0" expression=""/>
    <default field="cell_disapproved" applyOnUpdate="0" expression=""/>
    <default field="location_assessment" applyOnUpdate="0" expression=""/>
    <default field="is_scheduled" applyOnUpdate="0" expression=""/>
    <default field="teammember_assigned" applyOnUpdate="0" expression=""/>
    <default field="activity_group_id" applyOnUpdate="0" expression=""/>
    <default field="date_visit_planned" applyOnUpdate="0" expression=""/>
    <default field="days_to_visit" applyOnUpdate="0" expression=""/>
    <default field="days_to_deadline" applyOnUpdate="0" expression=""/>
    <default field="priority" applyOnUpdate="0" expression=""/>
    <default field="preparation_notes" applyOnUpdate="0" expression=""/>
  </defaults>
  <constraints>
    <constraint constraints="0" notnull_strength="0" field="ogc_fid" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="location_id" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="grts_address" unique_strength="0" exp_strength="0"/>
    <constraint constraints="3" notnull_strength="1" field="extravisit_id" unique_strength="1" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="teammember_id" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="date_visit" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="type_assessed" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="notes" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="photo" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="visit_done" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="samplelocation_id" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="grts_join_method" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="scheme" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="panel_set" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="targetpanel" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="scheme_ps_targetpanels" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="sp_poststratum" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="type" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="assessment" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="assessment_date" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="is_replaced" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="replacement_ongoing" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="replacement_reason" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="replacement_permanence" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="assessment_done" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="cell_disapproved" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="location_assessment" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="is_scheduled" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="teammember_assigned" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="activity_group_id" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="date_visit_planned" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="days_to_visit" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="days_to_deadline" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="priority" unique_strength="0" exp_strength="0"/>
    <constraint constraints="0" notnull_strength="0" field="preparation_notes" unique_strength="0" exp_strength="0"/>
  </constraints>
  <constraintExpressions>
    <constraint desc="" field="ogc_fid" exp=""/>
    <constraint desc="" field="location_id" exp=""/>
    <constraint desc="" field="grts_address" exp=""/>
    <constraint desc="" field="extravisit_id" exp=""/>
    <constraint desc="" field="teammember_id" exp=""/>
    <constraint desc="" field="date_visit" exp=""/>
    <constraint desc="" field="type_assessed" exp=""/>
    <constraint desc="" field="notes" exp=""/>
    <constraint desc="" field="photo" exp=""/>
    <constraint desc="" field="visit_done" exp=""/>
    <constraint desc="" field="samplelocation_id" exp=""/>
    <constraint desc="" field="grts_join_method" exp=""/>
    <constraint desc="" field="scheme" exp=""/>
    <constraint desc="" field="panel_set" exp=""/>
    <constraint desc="" field="targetpanel" exp=""/>
    <constraint desc="" field="scheme_ps_targetpanels" exp=""/>
    <constraint desc="" field="sp_poststratum" exp=""/>
    <constraint desc="" field="type" exp=""/>
    <constraint desc="" field="assessment" exp=""/>
    <constraint desc="" field="assessment_date" exp=""/>
    <constraint desc="" field="is_replaced" exp=""/>
    <constraint desc="" field="replacement_ongoing" exp=""/>
    <constraint desc="" field="replacement_reason" exp=""/>
    <constraint desc="" field="replacement_permanence" exp=""/>
    <constraint desc="" field="assessment_done" exp=""/>
    <constraint desc="" field="cell_disapproved" exp=""/>
    <constraint desc="" field="location_assessment" exp=""/>
    <constraint desc="" field="is_scheduled" exp=""/>
    <constraint desc="" field="teammember_assigned" exp=""/>
    <constraint desc="" field="activity_group_id" exp=""/>
    <constraint desc="" field="date_visit_planned" exp=""/>
    <constraint desc="" field="days_to_visit" exp=""/>
    <constraint desc="" field="days_to_deadline" exp=""/>
    <constraint desc="" field="priority" exp=""/>
    <constraint desc="" field="preparation_notes" exp=""/>
  </constraintExpressions>
  <expressionfields/>
  <attributeactions>
    <defaultAction value="{00000000-0000-0000-0000-000000000000}" key="Canvas"/>
  </attributeactions>
  <attributetableconfig actionWidgetStyle="dropDown" sortExpression="&quot;date_visit_planned&quot;" sortOrder="0">
    <columns>
      <column type="field" hidden="0" name="ogc_fid" width="-1"/>
      <column type="field" hidden="0" name="location_id" width="-1"/>
      <column type="field" hidden="0" name="grts_address" width="-1"/>
      <column type="field" hidden="0" name="extravisit_id" width="-1"/>
      <column type="field" hidden="0" name="teammember_id" width="-1"/>
      <column type="field" hidden="0" name="date_visit" width="-1"/>
      <column type="field" hidden="0" name="type_assessed" width="-1"/>
      <column type="field" hidden="0" name="notes" width="-1"/>
      <column type="field" hidden="0" name="photo" width="-1"/>
      <column type="field" hidden="0" name="visit_done" width="-1"/>
      <column type="field" hidden="0" name="grts_join_method" width="-1"/>
      <column type="field" hidden="0" name="scheme" width="-1"/>
      <column type="field" hidden="0" name="panel_set" width="-1"/>
      <column type="field" hidden="0" name="targetpanel" width="-1"/>
      <column type="field" hidden="0" name="scheme_ps_targetpanels" width="-1"/>
      <column type="field" hidden="0" name="sp_poststratum" width="-1"/>
      <column type="field" hidden="0" name="type" width="-1"/>
      <column type="field" hidden="0" name="assessment" width="-1"/>
      <column type="field" hidden="0" name="assessment_date" width="-1"/>
      <column type="field" hidden="0" name="is_replaced" width="-1"/>
      <column type="field" hidden="0" name="location_assessment" width="-1"/>
      <column type="field" hidden="0" name="cell_disapproved" width="-1"/>
      <column type="field" hidden="0" name="is_scheduled" width="-1"/>
      <column type="field" hidden="0" name="teammember_assigned" width="-1"/>
      <column type="field" hidden="0" name="date_visit_planned" width="-1"/>
      <column type="field" hidden="0" name="preparation_notes" width="-1"/>
      <column type="field" hidden="0" name="assessment_done" width="-1"/>
      <column type="field" hidden="0" name="activity_group_id" width="-1"/>
      <column type="field" hidden="0" name="replacement_ongoing" width="-1"/>
      <column type="field" hidden="0" name="samplelocation_id" width="-1"/>
      <column type="field" hidden="0" name="replacement_reason" width="-1"/>
      <column type="field" hidden="0" name="replacement_permanence" width="-1"/>
      <column type="field" hidden="0" name="days_to_deadline" width="-1"/>
      <column type="field" hidden="0" name="priority" width="-1"/>
      <column type="field" hidden="0" name="days_to_visit" width="-1"/>
      <column type="actions" hidden="1" width="-1"/>
    </columns>
  </attributetableconfig>
  <conditionalstyles>
    <rowstyles/>
    <fieldstyles/>
  </conditionalstyles>
  <storedexpressions/>
  <editform tolerant="1"></editform>
  <editforminit/>
  <editforminitcodesource>0</editforminitcodesource>
  <editforminitfilepath></editforminitfilepath>
  <editforminitcode><![CDATA[# -*- coding: utf-8 -*-
"""
QGIS forms can have a Python function that is called when the form is
opened.

Use this function to add extra logic to your forms.

Enter the name of the function in the "Python Init function"
field.
An example follows:
"""
from qgis.PyQt.QtWidgets import QWidget

def my_form_open(dialog, layer, feature):
    geom = feature.geometry()
    control = dialog.findChild(QWidget, "MyLineEdit")
]]></editforminitcode>
  <featformsuppress>0</featformsuppress>
  <editorlayout>tablayout</editorlayout>
  <attributeEditorForm>
    <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
      <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
    </labelStyle>
    <attributeEditorContainer collapsedExpressionEnabled="0" horizontalStretch="0" visibilityExpressionEnabled="0" type="Tab" columnCount="1" groupBox="0" visibilityExpression="" name="info" collapsedExpression="" showLabel="1" collapsed="0" verticalStretch="0">
      <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
        <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
      </labelStyle>
      <attributeEditorField horizontalStretch="0" index="2" name="grts_address" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="17" name="type" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="19" name="assessment_date" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="18" name="assessment" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="25" name="cell_disapproved" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="26" name="location_assessment" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="28" name="teammember_assigned" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="30" name="date_visit_planned" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="31" name="days_to_visit" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="29" name="activity_group_id" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="34" name="preparation_notes" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
    </attributeEditorContainer>
    <attributeEditorContainer collapsedExpressionEnabled="0" horizontalStretch="0" visibilityExpressionEnabled="0" type="Tab" columnCount="1" groupBox="0" visibilityExpression="" name="activiteit" collapsedExpression="" showLabel="1" collapsed="0" verticalStretch="0">
      <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
        <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
      </labelStyle>
      <attributeEditorField horizontalStretch="0" index="4" name="teammember_id" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="5" name="date_visit" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="6" name="type_assessed" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="21" name="replacement_ongoing" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="7" name="notes" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="8" name="photo" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="9" name="visit_done" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
    </attributeEditorContainer>
    <attributeEditorContainer collapsedExpressionEnabled="0" horizontalStretch="0" visibilityExpressionEnabled="1" type="Tab" columnCount="1" groupBox="0" visibilityExpression="&quot;replacement_ongoing&quot;" name="lokale vervanging" collapsedExpression="" showLabel="1" collapsed="0" verticalStretch="0">
      <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
        <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
      </labelStyle>
      <attributeEditorField horizontalStretch="0" index="22" name="replacement_reason" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="23" name="replacement_permanence" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
      <attributeEditorField horizontalStretch="0" index="20" name="is_replaced" showLabel="1" verticalStretch="0">
        <labelStyle labelColor="" overrideLabelColor="0" overrideLabelFont="0">
          <labelFont italic="0" strikethrough="0" style="" underline="0" bold="0" description="Cantarell,10,-1,5,50,0,0,0,0,0"/>
        </labelStyle>
      </attributeEditorField>
    </attributeEditorContainer>
  </attributeEditorForm>
  <editable>
    <field name="activity_group_id" editable="0"/>
    <field name="assessment" editable="0"/>
    <field name="assessment_date" editable="0"/>
    <field name="assessment_done" editable="1"/>
    <field name="cell_disapproved" editable="0"/>
    <field name="date_visit" editable="1"/>
    <field name="date_visit_planned" editable="0"/>
    <field name="days_to_deadline" editable="1"/>
    <field name="days_to_visit" editable="0"/>
    <field name="extravisit_id" editable="1"/>
    <field name="grouped_activity_id" editable="1"/>
    <field name="grts_address" editable="0"/>
    <field name="grts_join_method" editable="1"/>
    <field name="is_replaced" editable="1"/>
    <field name="is_scheduled" editable="1"/>
    <field name="location_assessment" editable="0"/>
    <field name="location_id" editable="1"/>
    <field name="notes" editable="1"/>
    <field name="ogc_fid" editable="1"/>
    <field name="panel_set" editable="1"/>
    <field name="photo" editable="1"/>
    <field name="preparation_notes" editable="0"/>
    <field name="priority" editable="1"/>
    <field name="replacement_ongoing" editable="1"/>
    <field name="replacement_permanence" editable="1"/>
    <field name="replacement_reason" editable="1"/>
    <field name="samplelocation_id" editable="0"/>
    <field name="scheme" editable="1"/>
    <field name="scheme_ps_targetpanels" editable="1"/>
    <field name="sp_poststratum" editable="1"/>
    <field name="targetpanel" editable="1"/>
    <field name="teammember_assigned" editable="0"/>
    <field name="teammember_id" editable="1"/>
    <field name="type" editable="0"/>
    <field name="type_assessed" editable="1"/>
    <field name="visit_done" editable="1"/>
  </editable>
  <labelOnTop>
    <field labelOnTop="0" name="activity_group_id"/>
    <field labelOnTop="0" name="assessment"/>
    <field labelOnTop="0" name="assessment_date"/>
    <field labelOnTop="0" name="assessment_done"/>
    <field labelOnTop="0" name="cell_disapproved"/>
    <field labelOnTop="0" name="date_visit"/>
    <field labelOnTop="0" name="date_visit_planned"/>
    <field labelOnTop="0" name="days_to_deadline"/>
    <field labelOnTop="0" name="days_to_visit"/>
    <field labelOnTop="0" name="extravisit_id"/>
    <field labelOnTop="0" name="grouped_activity_id"/>
    <field labelOnTop="0" name="grts_address"/>
    <field labelOnTop="0" name="grts_join_method"/>
    <field labelOnTop="0" name="is_replaced"/>
    <field labelOnTop="0" name="is_scheduled"/>
    <field labelOnTop="0" name="location_assessment"/>
    <field labelOnTop="0" name="location_id"/>
    <field labelOnTop="0" name="notes"/>
    <field labelOnTop="0" name="ogc_fid"/>
    <field labelOnTop="0" name="panel_set"/>
    <field labelOnTop="0" name="photo"/>
    <field labelOnTop="0" name="preparation_notes"/>
    <field labelOnTop="0" name="priority"/>
    <field labelOnTop="0" name="replacement_ongoing"/>
    <field labelOnTop="0" name="replacement_permanence"/>
    <field labelOnTop="0" name="replacement_reason"/>
    <field labelOnTop="0" name="samplelocation_id"/>
    <field labelOnTop="0" name="scheme"/>
    <field labelOnTop="0" name="scheme_ps_targetpanels"/>
    <field labelOnTop="0" name="sp_poststratum"/>
    <field labelOnTop="0" name="targetpanel"/>
    <field labelOnTop="0" name="teammember_assigned"/>
    <field labelOnTop="0" name="teammember_id"/>
    <field labelOnTop="0" name="type"/>
    <field labelOnTop="0" name="type_assessed"/>
    <field labelOnTop="0" name="visit_done"/>
  </labelOnTop>
  <reuseLastValue>
    <field reuseLastValue="0" name="activity_group_id"/>
    <field reuseLastValue="0" name="assessment"/>
    <field reuseLastValue="0" name="assessment_date"/>
    <field reuseLastValue="0" name="assessment_done"/>
    <field reuseLastValue="0" name="cell_disapproved"/>
    <field reuseLastValue="0" name="date_visit"/>
    <field reuseLastValue="0" name="date_visit_planned"/>
    <field reuseLastValue="0" name="days_to_deadline"/>
    <field reuseLastValue="0" name="days_to_visit"/>
    <field reuseLastValue="0" name="extravisit_id"/>
    <field reuseLastValue="0" name="grouped_activity_id"/>
    <field reuseLastValue="0" name="grts_address"/>
    <field reuseLastValue="0" name="grts_join_method"/>
    <field reuseLastValue="0" name="is_replaced"/>
    <field reuseLastValue="0" name="is_scheduled"/>
    <field reuseLastValue="0" name="location_assessment"/>
    <field reuseLastValue="0" name="location_id"/>
    <field reuseLastValue="0" name="notes"/>
    <field reuseLastValue="0" name="ogc_fid"/>
    <field reuseLastValue="0" name="panel_set"/>
    <field reuseLastValue="0" name="photo"/>
    <field reuseLastValue="0" name="preparation_notes"/>
    <field reuseLastValue="0" name="priority"/>
    <field reuseLastValue="0" name="replacement_ongoing"/>
    <field reuseLastValue="0" name="replacement_permanence"/>
    <field reuseLastValue="0" name="replacement_reason"/>
    <field reuseLastValue="0" name="samplelocation_id"/>
    <field reuseLastValue="0" name="scheme"/>
    <field reuseLastValue="0" name="scheme_ps_targetpanels"/>
    <field reuseLastValue="0" name="sp_poststratum"/>
    <field reuseLastValue="0" name="targetpanel"/>
    <field reuseLastValue="0" name="teammember_assigned"/>
    <field reuseLastValue="0" name="teammember_id"/>
    <field reuseLastValue="0" name="type"/>
    <field reuseLastValue="0" name="type_assessed"/>
    <field reuseLastValue="0" name="visit_done"/>
  </reuseLastValue>
  <dataDefinedFieldProperties/>
  <widgets/>
  <previewExpression>represent_value( "activity_group_id" )</previewExpression>
  <mapTip enabled="1"></mapTip>
  <layerGeometryType>0</layerGeometryType>
</qgis>
