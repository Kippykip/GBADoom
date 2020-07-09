'---------------------------------------------------------------------------------------------------
' This program was written with BLIde (www.blide.org)
' Application: GBA Graphics library, drawing + converting algorithms etc.
' Author: Kippykip
' License: do whatever you fucken want
'---------------------------------------------------------------------------------------------------

Type GFX
	Global Palette:TBank
	Global PaletteLoaded = False
	
	Function KDrawPlot(TMP_X:Int = 0, TMP_Y:Int = 0, TMP_PIndex:Int = 0) 
		GFX.KLoadPalette() 
		SetColor(PeekByte(Palette, TMP_PIndex * 3), PeekByte(Palette, TMP_PIndex * 3 + 1), PeekByte(Palette, TMP_PIndex * 3 + 2)) 
		Plot(TMP_X, TMP_Y) 
	EndFunction
	Function KDrawRect(TMP_X:Int = 0, TMP_Y:Int = 0, TMP_Width = 16, TMP_Height = 16, TMP_PIndex:Int = 0, TMP_IsSolid = True) 
		GFX.KLoadPalette() 
		SetColor(PeekByte(Palette, TMP_PIndex * 3), PeekByte(Palette, TMP_PIndex * 3 + 1), PeekByte(Palette, TMP_PIndex * 3 + 2)) 
		DrawRect(TMP_X, TMP_Y, TMP_Width, TMP_Height) 
		SetColor(255, 255, 255) 
	EndFunction
	Function KDrawLine(TMP_X:Int = 0, TMP_Y:Int = 0, TMP_Width = 16, TMP_Height = 16, TMP_PIndex:Int = 0) 
		GFX.KLoadPalette() 
		SetColor(PeekByte(Palette, TMP_PIndex * 3), PeekByte(Palette, TMP_PIndex * 3 + 1), PeekByte(Palette, TMP_PIndex * 3 + 2)) 
		DrawLine(TMP_X, TMP_Y, TMP_Width, TMP_Height) 
		SetColor(255, 255, 255) 
	EndFunction
	rem
	Function KDrawIMG(TMP_FileName:String, TMP_X:Int = 0, TMP_Y:Int = 0, TMP_IMGWidth:Int = 0, TMP_IMGHeight:Int = 0) 
		Local TMP_IMG = LoadBank(TMP_FileName:String) 
		Local TMP_IMGStream:TStream = CreateBankStream(TMP_IMG) 
		Local TMP_Header:String = ""
		For x = 1 To 8
			TMP_Header:String = TMP_Header:String + Chr:String(ReadByte(TMP_IMGStream)) 
		Next
		If(TMP_Header:String = "KGRAPHIC") 
			TMP_IMGWidth:Int = ReadInt(TMP_IMGStream) 
			TMP_IMGHeight:Int = ReadInt(TMP_IMGStream) 
			For y = 0 To TMP_IMGHeight:Int - 1
				For x = 0 To TMP_IMGWidth:Int - 1
				'	GFX.KDrawPlot(TMP_X + x, TMP_Y + y, ReadByte(TMP_IMGStream) + TMP_ColourOffset:Int, TMP_ColourOffset:Int) 
				Next
			Next

		EndIf
		SetColor(255, 255, 255) 
		'Print TMP_Header:String
	EndFunction
	EndRem
	
	'Converts a raw image into a OpenGL ram image or whatever the fuck,
	'Way better performance this way, also can be recycled for PNG conversion.
	Function KConvertImage:TImage(TMP_FileName:String, TMP_IMGWidth:Int = 0, TMP_IMGHeight:Int = 0, TMP_DisableAlpha = False, TMP_ExportPNG = False, TMP_DestPNGFN:String = "conv.png") 
		Local TMP_IMG = LoadBank(TMP_FileName:String) 
		Local TMP_IMGStream:TStream = CreateBankStream(TMP_IMG) 
		Local TMP_Pixmap:TPixmap
		TMP_Pixmap:TPixmap = CreatePixmap(TMP_IMGWidth:Int, TMP_IMGHeight:Int, PF_RGBA8888) 
		ClearPixels(TMP_Pixmap) 
		For y = 0 To TMP_IMGHeight:Int - 1
			For x = 0 To TMP_IMGWidth:Int - 1
				TMP_Colour:Int = ReadByte(TMP_IMGStream) 
				'GFX.KDrawPlot(x, y, ReadByte(TMP_IMGStream)) 
				'Transparent
				If(TMP_Colour > 0 + TMP_ColourOffset:Int Or TMP_DisableAlpha) 
					WritePixel(TMP_Pixmap:TPixmap, x, y, GFX.RGBA_GetRGB(GFX.KGetRed(TMP_Colour:Int), GFX.KGetGreen(TMP_Colour:Int), GFX.KGetBlue(TMP_Colour:Int), 255)) 
				Else
					WritePixel(TMP_Pixmap:TPixmap, x, y, GFX.RGBA_GetRGB(0, 0, 0, 0)) 
				EndIf
			Next
		Next
		If(TMP_ExportPNG) 
			SavePixmapPNG(TMP_Pixmap:TPixmap, TMP_DestPNGFN:String) 
			'Return TMP_Pixmap:TPixmap
		Else
			Local TMP_ConvImage:TImage = LoadImage(TMP_Pixmap:TPixmap, DYNAMICIMAGE) 
			'Local TMP_ConvImage:TImage = CreateImage(TMP_IMGWidth, TMP_IMGHeight, 1, TMP_Flags) 
			'GrabImage(TMP_ConvImage, 0, 0) 
			SetColor(255, 255, 255) 
			Return TMP_ConvImage
		EndIf
		CloseFile(TMP_IMGStream:TStream) 
	EndFunction
	
	'Converts a raw texture into a OpenGL ram image or whatever the fuck,
	'Way better performance this way, also can be recycled for PNG conversion.
	'Also textures/flats are the same as normal images except Y is filled before it goes to the next x row
	Function KConvertTexture:TImage(TMP_FileName:String, TMP_IMGWidth:Int = 0, TMP_IMGHeight:Int = 0, TMP_DisableAlpha = False, TMP_ExportPNG = False, TMP_DestPNGFN:String = "conv.png") 
		Local TMP_IMG = LoadBank(TMP_FileName:String) 
		Local TMP_IMGStream:TStream = CreateBankStream(TMP_IMG) 
		Local TMP_Pixmap:TPixmap
		TMP_Pixmap:TPixmap = CreatePixmap(TMP_IMGWidth:Int, TMP_IMGHeight:Int, PF_RGBA8888) 
		ClearPixels(TMP_Pixmap) 
		For x = 0 To TMP_IMGWidth:Int - 1
			For y = 0 To TMP_IMGHeight:Int - 1
				TMP_Colour:Int = ReadByte(TMP_IMGStream) 
				'GFX.KDrawPlot(x, y, ReadByte(TMP_IMGStream)) 
				'Transparent
				If(TMP_Colour > 0 + TMP_ColourOffset:Int Or TMP_DisableAlpha) 
					WritePixel(TMP_Pixmap:TPixmap, x, y, GFX.RGBA_GetRGB(GFX.KGetRed(TMP_Colour:Int), GFX.KGetGreen(TMP_Colour:Int), GFX.KGetBlue(TMP_Colour:Int), 255)) 
				Else
					WritePixel(TMP_Pixmap:TPixmap, x, y, GFX.RGBA_GetRGB(0, 0, 0, 0)) 
				EndIf
			Next
		Next
		If(TMP_ExportPNG) 
			SavePixmapPNG(TMP_Pixmap:TPixmap, TMP_DestPNGFN:String) 
			'Return TMP_Pixmap:TPixmap
		Else
			Local TMP_ConvImage:TImage = LoadImage(TMP_Pixmap:TPixmap, DYNAMICIMAGE) 
			'Local TMP_ConvImage:TImage = CreateImage(TMP_IMGWidth, TMP_IMGHeight, 1, TMP_Flags) 
			'GrabImage(TMP_ConvImage, 0, 0) 
			SetColor(255, 255, 255) 
			Return TMP_ConvImage
		EndIf
		CloseFile(TMP_IMGStream:TStream) 
	EndFunction
	
	'Converts a palette into a OpenGL PNG ram image or whatever the fuck,
	Function KConvertPalette:TImage(TMP_FileName:String, TMP_ExportPNG = False, TMP_DestPNGFN:String = "conv.png") 
		Local TMP_IMG = LoadBank(TMP_FileName:String) 
		Local TMP_IMGStream:TStream = CreateBankStream(TMP_IMG) 
		Local TMP_Pixmap:TPixmap
		TMP_Pixmap:TPixmap = CreatePixmap(16, 16, PF_RGBA8888) 
		ClearPixels(TMP_Pixmap) 
		For y = 0 To 16 - 1
			For x = 0 To 16 - 1
				TMP_Red = ReadByte(TMP_IMGStream) 
				TMP_Green = ReadByte(TMP_IMGStream) 
				TMP_Blue = ReadByte(TMP_IMGStream) 
				WritePixel(TMP_Pixmap:TPixmap, x, y, GFX.RGBA_GetRGB(TMP_Red, TMP_Green, TMP_Blue, 255)) 
			Next
		Next
		If(TMP_ExportPNG) 
			SavePixmapPNG(TMP_Pixmap:TPixmap, TMP_DestPNGFN:String) 
			'Return TMP_Pixmap:TPixmap
		Else
			Local TMP_ConvImage:TImage = LoadImage(TMP_Pixmap:TPixmap, DYNAMICIMAGE) 
			SetColor(255, 255, 255) 
			Return TMP_ConvImage
		EndIf
		CloseFile(TMP_IMGStream:TStream) 
	EndFunction
	
	'Why not recycle code from one of my other projects? It's almost identical anyway!
	Function PNG2Palette:TBank(TMP_FileName:String, TMP_DestTEXFN:String = "conv.d2p") 
		SourceImage:TImage = LoadImage(TMP_FileName:String, DYNAMICIMAGE) 
		KGRAPHIC_File:TStream = WriteFile(TMP_DestTEXFN:String) 
		TMP_Pixmap:TPixmap = LockImage(SourceImage:TImage) 
		For y = 0 To 16 - 1
			For x = 0 To 16 - 1
				TMP_RGBA = TMP_Pixmap.ReadPixel(x, y) 
				WriteByte(KGRAPHIC_File, GFX.RGBA_GetRed(TMP_RGBA)) 
				WriteByte(KGRAPHIC_File, GFX.RGBA_GetGreen(TMP_RGBA)) 
				WriteByte(KGRAPHIC_File, GFX.RGBA_GetBlue(TMP_RGBA)) 
			Next
		Next
		CloseFile(KGRAPHIC_File:TStream) 
	End Function
	
	Function PNG2Image:TBank(TMP_FileName:String, TMP_DestTEXFN:String = "conv.d2t") 
		SourceImage:TImage = LoadImage(TMP_FileName:String, DYNAMICIMAGE) 
		KGRAPHIC_File:TStream = WriteFile(TMP_DestTEXFN:String) 
		Pixmap:TPixmap = LockImage(SourceImage:TImage) 
		For y = 0 To ImageHeight(SourceImage) - 1
			For x = 0 To ImageWidth(SourceImage) - 1
				TMP_RGBA = Pixmap.ReadPixel(x, y) 
				TMP_Difference:Int = 1024
				TMP_FINPalID:Int = 0
				If(GFX.RGBA_GetAlpha(TMP_RGBA) > 127) 
					'Start at 1 since 0 is transparent
					For TMP_PIndex = 1 To BankSize(GFX.Palette) / 3 - 1
						'Print RGBA_GetRed(RGBA) + ":" + RGBA_GetGreen(RGBA) + ":" + RGBA_GetBlue(RGBA) 
						TMP_Red:Int = PeekByte(GFX.Palette, TMP_PIndex * 3) 
						TMP_Green:Int = PeekByte(GFX.Palette, TMP_PIndex * 3 + 1) 
						TMP_Blue:Int = PeekByte(GFX.Palette, TMP_PIndex * 3 + 2) 
						
						TMP_RedDiff:Int = TMP_Red:Int - GFX.RGBA_GetRed(TMP_RGBA) 
						TMP_GreenDiff:Int = TMP_Green:Int - GFX.RGBA_GetGreen(TMP_RGBA) 
						TMP_BlueDiff:Int = TMP_Blue:Int - GFX.RGBA_GetBlue(TMP_RGBA) 
						If(TMP_RedDiff < 0) 
							TMP_RedDiff = TMP_RedDiff * -1
						EndIf
						If(TMP_GreenDiff < 0) 
							TMP_GreenDiff = TMP_GreenDiff * -1
						EndIf
						If(TMP_BlueDiff < 0) 
							TMP_BlueDiff = TMP_BlueDiff * -1
						EndIf
						If(TMP_RedDiff + TMP_GreenDiff + TMP_BlueDiff < TMP_Difference) 
							TMP_Difference = TMP_RedDiff + TMP_GreenDiff + TMP_BlueDiff
							TMP_FINPalID:Int = TMP_PIndex
						EndIf
						'Print TMP_RedDiff + ":" + TMP_GreenDiff + ":" + TMP_BlueDiff
					Next
					WriteByte(KGRAPHIC_File, TMP_FINPalID) 
				Else
					WriteByte(KGRAPHIC_File, 0) 
				EndIf
			Next
		Next
		CloseFile(KGRAPHIC_File:TStream) 
	End Function
	
	'Same as above but vertical
	Function PNG2Texture:TBank(TMP_FileName:String, TMP_DestTEXFN:String = "conv.d2t") 
		SourceImage:TImage = LoadImage(TMP_FileName:String, DYNAMICIMAGE) 
		KGRAPHIC_File:TStream = WriteFile(TMP_DestTEXFN:String) 
		Pixmap:TPixmap = LockImage(SourceImage:TImage) 
		For x = 0 To ImageWidth(SourceImage) - 1
			For y = 0 To ImageHeight(SourceImage) - 1
				TMP_RGBA = Pixmap.ReadPixel(x, y) 
				TMP_Difference:Int = 1024
				TMP_FINPalID:Int = 0
				If(GFX.RGBA_GetAlpha(TMP_RGBA) > 0) 
					'Start at 1 since 0 is transparent
					For TMP_PIndex = 1 To BankSize(GFX.Palette) / 3 - 1
						'Print RGBA_GetRed(RGBA) + ":" + RGBA_GetGreen(RGBA) + ":" + RGBA_GetBlue(RGBA) 
						TMP_Red:Int = PeekByte(GFX.Palette, TMP_PIndex * 3) 
						TMP_Green:Int = PeekByte(GFX.Palette, TMP_PIndex * 3 + 1) 
						TMP_Blue:Int = PeekByte(GFX.Palette, TMP_PIndex * 3 + 2) 
						
						TMP_RedDiff:Int = TMP_Red:Int - GFX.RGBA_GetRed(TMP_RGBA) 
						TMP_GreenDiff:Int = TMP_Green:Int - GFX.RGBA_GetGreen(TMP_RGBA) 
						TMP_BlueDiff:Int = TMP_Blue:Int - GFX.RGBA_GetBlue(TMP_RGBA) 
						If(TMP_RedDiff < 0) 
							TMP_RedDiff = TMP_RedDiff * -1
						EndIf
						If(TMP_GreenDiff < 0) 
							TMP_GreenDiff = TMP_GreenDiff * -1
						EndIf
						If(TMP_BlueDiff < 0) 
							TMP_BlueDiff = TMP_BlueDiff * -1
						EndIf
						If(TMP_RedDiff + TMP_GreenDiff + TMP_BlueDiff < TMP_Difference) 
							TMP_Difference = TMP_RedDiff + TMP_GreenDiff + TMP_BlueDiff
							TMP_FINPalID:Int = TMP_PIndex
						EndIf
						'Print TMP_RedDiff + ":" + TMP_GreenDiff + ":" + TMP_BlueDiff
					Next
					WriteByte(KGRAPHIC_File, TMP_FINPalID) 
				Else
					WriteByte(KGRAPHIC_File, 0) 
				EndIf
			Next
		Next
		CloseFile(KGRAPHIC_File:TStream) 
	End Function
	
	Function PNGMirror(TMP_FileName:String, TMP_DestFileName:String) 
		TMP_SourceImage:TImage = LoadImage(TMP_FileName:String, DYNAMICIMAGE) 
		TMP_SourcePixmap:TPixmap = LockImage(TMP_SourceImage:TImage) 
		TMP_NewPixmap:TPixmap = CreatePixmap(ImageWidth(TMP_SourceImage:TImage), ImageHeight(TMP_SourceImage:TImage), PF_RGBA8888) 
		'Copy pixels from regular image to the bigger/smaller canvs.
		For y = 0 To ImageHeight(TMP_SourceImage:TImage) - 1
			For x = 0 To ImageWidth(TMP_SourceImage:TImage) - 1
				TMP_RGBA = TMP_SourcePixmap.ReadPixel(x, y) 
				WritePixel(TMP_NewPixmap:TPixmap, ImageWidth(TMP_SourceImage:TImage) - 1 - x, y, GFX.RGBA_GetRGB(GFX.RGBA_GetRed(TMP_RGBA), GFX.RGBA_GetGreen(TMP_RGBA), GFX.RGBA_GetBlue(TMP_RGBA), GFX.RGBA_GetAlpha(TMP_RGBA))) 
			Next
		Next
		SavePixmapPNG(TMP_NewPixmap:TPixmap, TMP_DestFileName:String) 
	EndFunction
	
	Function PNGResizeCanvas(TMP_FileName:String, TMP_DestFileName:String, TMP_NewWidth:Int, TMP_NewHeight:Int, TMP_FullCenter = False, TMP_ContainsM = False) 
		TMP_SourceImage:TImage = LoadImage(TMP_FileName:String, DYNAMICIMAGE) 
		If(ImageWidth(TMP_SourceImage:TImage) <> TMP_NewWidth:Int or ImageHeight(TMP_SourceImage:TImage) <> TMP_NewHeight:Int) 
			TMP_SourcePixmap:TPixmap = LockImage(TMP_SourceImage:TImage) 
			TMP_NewPixmap:TPixmap = CreatePixmap(TMP_NewWidth:int, TMP_NewHeight:int, PF_RGBA8888) 
			ClearPixels(TMP_NewPixmap:TPixmap) 
			'Gotta do some weird float calculations since half the doom graphics have non-even widths.
			TMP_OffsetX:Float = Int(Float(TMP_NewWidth:Int) / 2 - (Float(ImageWidth(TMP_SourceImage:TImage)) / 2))           		'X offset to start drawing
			TMP_OffsetY:Float = TMP_NewHeight:Int - ImageHeight(TMP_SourceImage:TImage)         										'Y offset to start drawing
			'Small fix for the mirrored sprites
			If(TMP_ContainsM) 
				Print "PNGResizeCanvas: Mirrored sprite detected, adjusting..."
				TMP_OffsetX:Float = Int(Float(TMP_NewWidth:Int) / 2 - (Float(ImageWidth(TMP_SourceImage:TImage)) / 2) + 0.5)             		'X offset to start drawing
			EndIf
			Print TMP_OffsetX:Float
			If(TMP_FullCenter) 
				Print "PNGResizeCanvas: Adjusting canvas to middle"
				TMP_OffsetY:Float = Int(Float(TMP_NewHeight:Int) / 2 - (Float(ImageHeight(TMP_SourceImage:TImage)) / 2))            	'Y offset to start drawing
				If(TMP_ContainsM) 
					TMP_OffsetY:Float = Int(Float(TMP_NewHeight:Int) / 2 - (Float(ImageHeight(TMP_SourceImage:TImage)) / 2) + 0.5)                 		'X offset to start drawing
				EndIf
			Else
				Print "PNGResizeCanvas: Adjusting canvas to bottom-middle"
			EndIf
			'Fill everything with transparent
			For y = 0 To TMP_NewHeight:int - 1
				For x = 0 To TMP_NewWidth:int - 1
					WritePixel(TMP_NewPixmap:TPixmap, x, y, GFX.RGBA_GetRGB(255, 255, 255, 0)) 
				Next
			Next
			'Copy pixels from regular image to the bigger/smaller canvs.
			For y = 0 To ImageHeight(TMP_SourceImage:TImage) - 1
				For x = 0 To ImageWidth(TMP_SourceImage:TImage) - 1
					TMP_RGBA = TMP_SourcePixmap.ReadPixel(x, y) 
					If(x + TMP_OffsetX:Float < TMP_NewWidth:Int And y + TMP_OffsetY:Float < TMP_NewHeight:Int) 
						If(x + TMP_OffsetX:Float >= 0 And y + TMP_OffsetY:Float >= 0) 
							WritePixel(TMP_NewPixmap:TPixmap, x + TMP_OffsetX:Float, y + TMP_OffsetY:Float, GFX.RGBA_GetRGB(GFX.RGBA_GetRed(TMP_RGBA), GFX.RGBA_GetGreen(TMP_RGBA), GFX.RGBA_GetBlue(TMP_RGBA), GFX.RGBA_GetAlpha(TMP_RGBA))) 
						EndIf
					EndIf
				Next
			Next
			SavePixmapPNG(TMP_NewPixmap:TPixmap, TMP_DestFileName:String) 
		Else
			Print "PNGResizeCanvas: No need to resize, canvas is the same."
		EndIf
	End Function
	
	'Just for debugging
	Function KGetColour:String(TMP_PIndex:Int) 
		GFX.KLoadPalette() 
		If(TMP_PIndex:Int < (BankSize(Palette) - 8) / 3) 
			Return "Index " + TMP_PIndex:Int + ": " + PeekByte(Palette, TMP_PIndex * 3 + 8) + " : " + PeekByte(Palette, TMP_PIndex * 3 + 9) + " : " + PeekByte(Palette, TMP_PIndex * 3 + 10) 
		Else
			Return "Index '" + TMP_PIndex:Int + "' is out of bounds! (Capacity is: " + ((BankSize(Palette) - 8) / 3 - 1) + ")"
		EndIf
	EndFunction
	
	Function KGetRed:Int(TMP_PIndex:Int) 
		GFX.KLoadPalette() 
		Return PeekByte(Palette, TMP_PIndex * 3) 
	EndFunction
	
	Function KGetGreen:Int(TMP_PIndex:Int) 
		GFX.KLoadPalette() 
		Return PeekByte(Palette, TMP_PIndex * 3 + 1) 
	EndFunction
	
	Function KGetBlue:Int(TMP_PIndex:Int) 
		GFX.KLoadPalette() 
		Return PeekByte(Palette, TMP_PIndex * 3 + 2) 
	EndFunction
	
	'Incase you forcibly need to load it.
	Function KLoadPalette(TMP_PaletteFN:String = "decompile\PALETTE\PLAYPAL.1.D2P") 
		If(PaletteLoaded = False) 
			Palette:TBank = LoadBank(TMP_PaletteFN:String) 
			If Not(Palette:TBank) 
				Notify("Palette doesn't exist! Please decompile first!", True) 
				End
			End If
			PaletteLoaded = True
		EndIf
	End Function
	
	'Some colour conversion code I ported and stole from:
	'http://www.budmelvin.com/dev/15bitconverter.html
	Function Convert8888to555:Short(TMP_Red:Int, TMP_Green:Int, TMP_Blue:Int) 
		TMP_ConvRed:String = Right:String(Bin:String(TMP_Red / 8), 5)    	'R
		TMP_ConvGreen:String = Right:String(Bin:String(TMP_Green / 8), 5)  	'G
		TMP_ConvBlue:String = Right:String(Bin:String(TMP_Blue / 8), 5) 	'B
		TMP_Final:String = TMP_ConvBlue:String + TMP_ConvGreen:String + TMP_ConvRed:String
		Return Short(BinToDec:Int(TMP_Final:String)) 
	EndFunction
	
	Function Convert555to8888_Red:Int(TMP_555:Short) 
		TMP_ConvRed:String = Right:String(Bin:String(TMP_555:Short), 5)        'R
		Return BinToDec:Int(TMP_ConvRed:String) * 8
	EndFunction
	
	Function Convert555to8888_Green:Int(TMP_555:Short) 
		TMP_ConvGreen:String = Mid:String(Bin:String(TMP_555:Short), Len(Bin:String(TMP_555:Short)) - 9, 5) 	'G
		Return BinToDec:Int(TMP_ConvGreen:String) * 8
	EndFunction
	
	Function Convert555to8888_Blue:Int(TMP_555:Short) 
		TMP_ConvBlue:String = Mid:String(Bin:String(TMP_555:Short), Len(Bin:String(TMP_555:Short)) - 14, 5) 	'B
		Return BinToDec:Int(TMP_ConvBlue:String) * 8
	EndFunction
	
	Function BinToDec:Int(TMP_Bin:String) 
		If TMP_Bin:String[0] <> 37 Then TMP_Bin:String = "%" + TMP_Bin:String
		Return Int(TMP_Bin:String) 
	End Function
	
	'Really good functions, why aren't they built in for fuck sake?
	'Also references here okay???
	
	'RGBA = Pixmap.ReadPixel(x, y) 
	'WriteByte(PALFLE, RGBA_GetRed(RGBA)) 
	'WriteByte(PALFLE, RGBA_GetGreen(RGBA)) 
	'WriteByte(PALFLE, RGBA_GetBlue(RGBA)) 
	Function RGBA_GetRed:Int(rgba:Int) 
		Return((rgba Shr 16) & $FF) 
	End Function
	Function RGBA_GetGreen:Int(rgba:Int) 
		Return((rgba Shr 8) & $FF) 
	End Function
	Function RGBA_GetBlue:Int(rgba:Int) 
		Return(rgba & $FF) 
	End Function
	Function RGBA_GetAlpha:Int(rgba:Int) 
		Return((rgba:Int Shr 24) & $FF) 
	End Function
	Function RGBA_GetRGB(red, green, blue, alpha = 255) 
		RGB = (alpha Shl 24) | (Red Shl 16) | (Green Shl 8) | Blue
		Return rgb
	End Function
EndType

'copies an TImage to not manipulate the source image
Function CopyImage:TImage(src:TImage)
   If src = Null Then Return Null

   Local dst:TImage = New TImage
   MemCopy(dst, src, SizeOf(dst))

   dst.pixmaps = New TPixmap[src.pixmaps.length]
   dst.frames = New TImageFrame[src.frames.length]
   dst.seqs = New Int[src.seqs.length]

   For i:Int = 0 To dst.pixmaps.length-1
      dst.pixmaps[i] = CopyPixmap(src.pixmaps[i])
   Next

   For i:Int = 0 To dst.frames.length - 1
      dst.Frame(i)
   Next

   MemCopy(dst.seqs, src.seqs, SizeOf(dst.seqs))

   Return dst
End Function

Function ScanDir:Float(folder:String) 
	DirCount:Float = 0
	FileCount:Float = 0

	myDir=ReadDir(folder$) 

	Repeat 
		file$=NextFile$(myDir) 

		If file$="" Then Exit 
	
		If FileType(folder$+"\"+file$) = 2 Then 
			If file$<>"." And file$<>".." Then
				ScanDir(folder$+"\"+file$)
				DirCount=DirCount+1
			EndIf
		Else 
			FileCount=FileCount+1
		End If 
	Forever 

	CloseDir myDir 
	Return FileCount:Float
End Function

'rem
'Graphics 640, 480, 0, 60
'ARCH_Init() 
'Print GFX.GetColour(256) 
'GFX.KDrawLine(8, 8, 32, 32, 19) 
'SetColor(255, 255, 255) 
'testicaal = CreateImage(5, 5) 
'GFX.KDrawIMG("SWASTIKA", 0, 0) 
'GrabImage(testicaal, 0, 0) 
'testicaal:TImage = GFX.KConvertImage("GAR", 0) 
'a = 0
'While Not AppTerminate() 
'	Cls
'	SetColor(255, 255, 255) 
'	DrawRect(0, 0, 640, 480) 
'	GFX.KDrawRect(0, 0, 32, 32, 256) 
'	For x = 1 To 1000
		
		 
		'TileImage(testicaal, 60, 0) 
'	Next
	'a = a + 1
	'DrawImageRect(testicaal, 0, 0, 640, 480) 
	'SetScale(8, 8) 
	'DrawImage(testicaal, 0, 0) 
	'frontbuffer 
'	Flip
'Wend
'WaitKey
'endrem
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               