﻿' Analog Clock模拟时钟
' Copyright (c) 2024 CM.Wang
' Freeware. Use at your own risk.

#include once "gdipAnalogClock.bi"

Private Constructor AnalogClock
	WLet(mBackFile, "")
	WLet(mTextFont, "Arial")
	WLet(mTextFormat, "h:mm:ss")
End Constructor

Private Destructor AnalogClock
	If mTextFormat Then Deallocate mTextFormat
	mTextFormat = NULL
	If mBackFile Then Deallocate mBackFile
	mBackFile = NULL
	If mTextFont Then Deallocate mTextFont
	mTextFont = NULL
End Destructor

Private Sub AnalogClock.Release()
	Deallocate mBackFile
	mBackFile = NULL
End Sub

Private Property AnalogClock.FileName(ByRef fFileName As WString)
	WLet(mBackFile, fFileName)
	mBackImage.ImageFile = *mBackFile
	If Dir(*mBackFile) = "" Then
		mBackScale = 1
	Else
		mBackScale = mBackImage.Height / mBackImage.Width
	End If
End Property

Private Property AnalogClock.FileName() ByRef As WString
	If mBackFile Then
		Return *mBackFile
	Else
		Return ""
	End If
End Property

Private Function AnalogClock.DrawText() As GpImage Ptr
	Dim tmpWStr As WString Ptr
	Static sTmpBitmap As gdipBitmap
	sTmpBitmap.Initial(mWidth, mHeight)
	
	Dim tmpTxt As gdipText
	tmpTxt.Initial(mWidth, mHeight)
	
	WLet(tmpWStr, Format(Now, *mTextFormat))
	tmpTxt.SetFont(*mTextFont, mWidth * mTextSize * mTextScale, IIf(mTextBold, FontStyleBold, FontStyleRegular))
	
	Dim sx As Single = (mWidth - tmpTxt.TextWidth(*tmpWStr)) / 2 * mTextOffsetX
	Dim sy As Single = (mHeight - tmpTxt.TextHeight(*tmpWStr)) / 2 * mTextOffsetY
	
	tmpTxt.TextOut(sTmpBitmap.Graphics, *tmpWStr, sx, sy, (mTextAlpha Shl 24) Or mTextColor)
	
	Deallocate tmpWStr
	Return sTmpBitmap.Image
End Function

Private Function AnalogClock.DrawTray() As GpImage Ptr
	Static sTmpBitmap As gdipBitmap
	
	Dim As Any Ptr hBrushL, hBrushLB, hPen, hPenL, hMatrix
	Dim As Single fBorderSize = mWidth * 0.03333
	Dim As Single fSize = mWidth * 0.9475 - fBorderSize / 2
	Dim As Single fRadius = mWidth / 2
	Dim As Single fShadow_vx = mWidth * 0.01
	Dim As Single fShadow_vy = mWidth * 0.01
	Dim As GpPointF tPoint1, tPoint2
	
	Dim As Single fPi, fRad, fDeg
	fPi = Acos(-1)
	fRad = fPi / 180
	fDeg = 180 / fPi
	Dim As Single fShadowAngle
	
	'准备画布和位图
	sTmpBitmap.Initial(mWidth, mWidth)
	
	tPoint1.X = fBorderSize
	tPoint1.Y = fBorderSize
	tPoint2.X = fSize
	tPoint2.Y = fSize
	GdipCreateLineBrush(@tPoint1, @tPoint2, mTrayFaceAlpha1 Shl 24 Or mTrayFaceColor1, mTrayFaceAlpha2 Shl 24 Or mTrayFaceColor2, WrapModeTileFlipXY, @hBrushLB)
	
	GdipSetLineSigmaBlend(hBrushLB, 0.5, 0.85)
	
	GdipCreateMatrix(@hMatrix)
	GdipTranslateMatrix(hMatrix, fSize * 2, fSize * 2, 1)
	GdipRotateMatrix(hMatrix, 90, 1)
	GdipTranslateMatrix(hMatrix, -fSize * 2, -fSize * 2, 1)
	GdipMultiplyLineTransform(hBrushLB, hMatrix, 0)
	GdipDeleteMatrix(hMatrix)
	
	'填充表盘底色
	GdipFillEllipse(sTmpBitmap.Graphics, hBrushLB, fBorderSize, fBorderSize, fSize, fSize)
	
	'绘制表盘阴影
	fShadowAngle = Atn(fShadow_vy / fShadow_vx) * fDeg
	If fShadow_vx < 0 And fShadow_vy >= 0 Then fShadowAngle += 180
	If fShadow_vx < 0 And fShadow_vy < 0 Then fShadowAngle -= 180
	GdipCreatePen1(mTrayShadowAlpha Shl 24 Or mTrayShadowColor, fBorderSize, UnitPixel, @hPen)
	GdipDrawEllipse(sTmpBitmap.Graphics, hPen, fBorderSize + fShadow_vx, fBorderSize + fShadow_vy, fSize, fSize)
	'阴影模糊处理
	FastBoxBlurHV(sTmpBitmap.Image, mWidth * 0.02)
	
	'绘制表盘边缘
	tPoint1.X = 0
	tPoint1.Y = 0
	tPoint2.X = fSize
	tPoint2.Y = fSize
	GdipCreateLineBrush(@tPoint1, @tPoint2, mTrayEdgeAlpha1 Shl 24 Or mTrayEdgeColor1, mTrayEdgeAlpha2 Shl 24 Or mTrayEdgeColor2, WrapModeTileFlipXY, @hBrushL)
	GdipSetLineSigmaBlend(hBrushL, 0.6, 1.0)
	GdipSetLineGammaCorrection(hBrushL, True)
	GdipCreatePen2(hBrushL, fBorderSize, UnitPixel, @hPenL)
	GdipDrawEllipse(sTmpBitmap.Graphics, hPenL, fBorderSize, fBorderSize, fSize, fSize)
	
	GdipDeleteBrush(hBrushL)
	GdipDeleteBrush(hBrushLB)
	GdipDeletePen(hPen)
	GdipDeletePen(hPenL)
	
	Return sTmpBitmap.Image
End Function

Private Function AnalogClock.DrawScale() As GpImage Ptr
	Dim As Single fRadius = mWidth / 2
	'刻度距离边缘
	Dim As Single fDistance = mWidth / 11
	'粗刻度
	Dim As Single iWidth1 = mWidth / 48, iHeight1 = mWidth / 15, iWidth12 = iWidth1 / 2
	'细刻度
	Dim As Single iWidth2 = mWidth / 100, iHeight2 = mWidth / 25, iWidth22 = iWidth2 / 2
	'准备画布和位图
	Static sTmpBitmap As gdipBitmap
	sTmpBitmap.Initial(mWidth, mWidth)
	'绘制表盘刻度
	Dim As Any Ptr hBrush
	GdipCreateSolidFill((mScaleAlpha Shl 24) Or mScaleColor, @hBrush)
	
	GdipTranslateWorldTransform(sTmpBitmap.Graphics, fRadius, fRadius, 0)
	GdipRotateWorldTransform(sTmpBitmap.Graphics, -6.0, MatrixOrderPrepend)
	GdipTranslateWorldTransform(sTmpBitmap.Graphics, -fRadius, -fRadius, 0)
	For i As UByte = 0 To 59
		GdipTranslateWorldTransform(sTmpBitmap.Graphics, fRadius, fRadius, 0)
		GdipRotateWorldTransform(sTmpBitmap.Graphics, 6.0, MatrixOrderPrepend)
		GdipTranslateWorldTransform(sTmpBitmap.Graphics, -fRadius, -fRadius, 0)
		If (i Mod 5) = 0 Then
			'绘制粗刻度
			GdipFillRectangle(sTmpBitmap.Graphics, hBrush, fRadius - iWidth12, fDistance, iWidth1, iHeight1)
		Else
			'绘制细刻度
			GdipFillRectangle(sTmpBitmap.Graphics, hBrush, fRadius - iWidth22, fDistance, iWidth2, iHeight2)
		End If
	Next
	GdipResetWorldTransform(sTmpBitmap.Graphics)
	GdipDeleteBrush(hBrush)
	
	Return sTmpBitmap.Image
End Function

Private Function AnalogClock.DrawHand() As GpImage Ptr
	Static sTmpBitmap As gdipBitmap
	Static SecBitmap As gdipBitmap
	
	'准备画布和位图
	sTmpBitmap.Initial(mWidth, mHeight)
	SecBitmap.Initial(mWidth, mHeight)
	
	Dim sTime As Double= VBTimer()
	Dim sHour As Double, sMinute As Double, sSecond As Double
	
	'时分秒
	sHour = sTime / 3600
	sMinute = sTime / 60 - Fix(sHour) * 60
	sSecond = sTime - Fix(sHour) * 3600 + Fix(sMinute) * 60
	
	'时分秒换算成角度
	Dim sHourAngle As Double, sMinuteAngle As Double, sSecondAngle As Double
	sHourAngle = mPi / 2 - sHour / 12 * 2 * mPi
	sMinuteAngle = mPi / 2 - sMinute / 60 * 2 * mPi
	sSecondAngle = mPi / 2 - sSecond / 60 * 2 * mPi
	
	If mHandHourEnabled Then
		'时针
		GdipDrawLine(sTmpBitmap.Graphics, mPenHour, mCenterX - mCenterX * mHandHourTail * Cos(sHourAngle), mCenterY + mCenterY * mHandHourTail * Sin(sHourAngle), mCenterX + (mCenterX * mHandHourFront) * Cos(sHourAngle), mCenterY - (mCenterY * mHandHourFront) * Sin(sHourAngle))
	End If
	If mHandMinuteEnabled Then
		'分针
		GdipDrawLine(sTmpBitmap.Graphics, mPenMinute, mCenterX - mCenterX * mHandMinuteTail * Cos(sMinuteAngle), mCenterY + mCenterY * mHandMinuteTail * Sin(sMinuteAngle), mCenterX + (mCenterX * mHandMinuteFront) * Cos(sMinuteAngle), mCenterY - (mCenterY * mHandMinuteFront) * Sin(sMinuteAngle))
	End If
	If mHandSecondEnabled Then
		'秒针
		GdipDrawLine(SecBitmap.Graphics, mPenSecond, mCenterX - mCenterX * mHandSecondTail * Cos(sSecondAngle), mCenterY + mCenterY * mHandSecondTail * Sin(sSecondAngle), mCenterX + (mCenterX * mHandSecondFront) * Cos(sSecondAngle), mCenterY - (mCenterY * mHandSecondFront) * Sin(sSecondAngle))
		
		'清除绘画
		Dim fPath As GpPath Ptr
		GdipCreatePath(FillModeAlternate, @fPath)
		GdipAddPathEllipse(fPath, mCenterX - mCenterX * mHandHourSize / 2, mCenterY - mCenterY * mHandHourSize / 2, mCenterX * mHandHourSize, mCenterY * mHandHourSize)
		GdipSetClipPath(SecBitmap.Graphics, fPath, CombineModeReplace)
		GdipGraphicsClear(SecBitmap.Graphics, 0)
		GdipDeletePath(fPath)
		GdipResetClip(SecBitmap.Graphics)
	End If
	
	GdipDrawEllipse(SecBitmap.Graphics, mPenSecond, mCenterX - mCenterX * mHandHourSize / 2, mCenterY - mCenterY * mHandHourSize / 2, mCenterX * mHandHourSize, mCenterY * mHandHourSize)
	
	sTmpBitmap.DrawImage(SecBitmap.Image, 0, 0)
	
	Return sTmpBitmap.Image
End Function

Private Sub AnalogClock.Background(ByVal pWidth As Single = 300, ByVal pHeight As Single = 400)
	mWidth = pWidth
	mHeight = pHeight
	Dim sTmpBitmap As gdipBitmap
	
	'时钟中心
	mCenterX = mWidth / 2 + mHandOffsetX
	mCenterY = mHeight / 2 + mHandOffsetY
	'时针大小
	mHandHourSize = 0.088 * mHandScale
	mHandMinuteSize = 0.066 * mHandScale
	mHandSecondSize = 0.033 * mHandScale
	'时针后端偏移
	mHandHourTail = 0.16 * mHandScale
	mHandMinuteTail = 0.16 * mHandScale
	mHandSecondTail = 0.22 * mHandScale
	'时针前端长度
	mHandHourFront = 0.62 * mHandScale
	mHandMinuteFront = 0.68 * mHandScale
	mHandSecondFront = 0.86 * mHandScale
	
	mAHourColor = mHandAlpha Shl 24 Or mHandHourColor
	mAMinuteColor = mHandAlpha Shl 24 Or mHandMinuteColor
	mASecondColor = mHandAlpha Shl 24 Or mHandSecondColor
	
	'释放资源
	If mPenHour Then GdipDeletePen(mPenHour)
	If mPenMinute Then GdipDeletePen(mPenMinute)
	If mPenSecond Then GdipDeletePen(mPenSecond)
	
	GdipCreatePen1(mAHourColor, mCenterX * mHandHourSize, UnitPixel, @mPenHour)
	GdipCreatePen1(mAMinuteColor, mCenterX * mHandMinuteSize, UnitPixel, @mPenMinute)
	GdipCreatePen1(mASecondColor, mCenterX * mHandSecondSize, UnitPixel, @mPenSecond)
	
	mBackBitmap.Initial(mWidth, mHeight)
	
	If mPanelEnabled Then
		sTmpBitmap.Initial(mWidth, mHeight)
		GdipGraphicsClear(sTmpBitmap.Graphics, mPanelAlpha Shl 24 Or mPanelColor)
		mBackBitmap.DrawImage(sTmpBitmap.Image, 0, 0)
	End If
	
	If mTrayEnabled Then
		sTmpBitmap.Initial(mWidth, mHeight)
		sTmpBitmap.DrawScaleImage(DrawTray())
		If mTrayBlur Then FastBoxBlurHV(sTmpBitmap.Image, mTrayBlur)
		mBackBitmap.DrawAlphaImage(sTmpBitmap.Image, mTrayAlpha)
	End If
	
	If mBackEnabled Then
		sTmpBitmap.Initial(mWidth, mHeight)
		sTmpBitmap.DrawScaleImage(mBackImage.Image)
		If mBackBlur Then FastBoxBlurHV(sTmpBitmap.Image, mBackBlur)
		mBackBitmap.DrawAlphaImage(sTmpBitmap.Image, mBackAlpha)
	End If
	
	If mScaleEnabled Then
		sTmpBitmap.Initial(mWidth, mHeight)
		sTmpBitmap.DrawImage(DrawScale(), 0, 0)
		If mScaleBlur Then FastBoxBlurHV(sTmpBitmap.Image, mScaleBlur)
		mBackBitmap.DrawImage(sTmpBitmap.Image, 0, 0)
	End If
	
	If mOutlineEnabled Then
		sTmpBitmap.Initial(mWidth, mHeight)
		Dim sPen As GpPen Ptr
		GdipCreatePen1((mOutlineAlpha Shl 24) Or mOutlineColor, mOutlineSize, UnitPixel, @sPen)
		GdipDrawRectangle(sTmpBitmap.Graphics, sPen, 0, 0, mWidth, mHeight)
		GdipDeletePen(sPen)
		mBackBitmap.DrawImage(sTmpBitmap.Image, 0, 0)
	End If
End Sub

Private Function AnalogClock.ImageUpdate() As GpImage Ptr
	mUpdateBitmap.Initial(mWidth, mHeight)
	mUpdateBitmap.DrawScaleImage(mBackBitmap.Image)
	
	Dim sImg As gdipImage
	If mTextEnabled Then
		sImg.Image = DrawText()
		If mTextBlur Then FastBoxBlurHV(sImg.Image, mTextBlur)
		mUpdateBitmap.DrawScaleImage(sImg.Image)
	End If
	If mHandEnabled Then
		sImg.Image = DrawHand()
		If mHandBlur Then FastBoxBlurHV(sImg.Image, mHandBlur)
		mUpdateBitmap.DrawScaleImage(sImg.Image)
	End If
	
	If mBlur Then
		FastBoxBlurHV(mUpdateBitmap.Image, mBlur)
	End If
	
	Return mUpdateBitmap.Image
End Function
