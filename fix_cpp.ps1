$enc = [System.Text.Encoding]::GetEncoding(936)
$content = [System.IO.File]::ReadAllText("E:\NX\source\MoveandCut\MoveandCut.cpp", $enc)

# Step 1: Find the end of getBodyBBox and insert readEnumIndex helper before apply_cb
$oldEnd = "UF_MODL_ask_bounding_box(b->Tag(), box);
    return true;
}"

$newHelper = @'
static int readEnumIndex(NXOpen::BlockStyler::Enumeration* e, int defaultVal)
{
    if (e == NULL) return defaultVal;
    try
    {
        NXOpen::BlockStyler::PropertyList* p = e->GetProperties();
        int val = defaultVal;
        try { val = p->GetInteger("Value"); }
        catch (...) { try { val = (int)p->GetDouble("Value"); } catch (...) { try { NXString s = p->GetString("Value"); val = atoi(s.GetText()); } catch (...) { } } }
        delete p;
        return val;
    }
    catch (...) { return defaultVal; }
}

'@

$idx = $content.IndexOf("int MoveandCut::apply_cb()")
if ($idx -ge 0) {
    Write-Host "Found apply_cb at index: $idx"
    $before = $content.Substring(0, $idx)
    $after = $content.Substring($idx)
    $content = $before + $newHelper + "
" + $after
    Write-Host "Helper inserted"
}

# Step 2: Replace old apply_cb body with new one
# Old key text to find the start of the body
$oldBody = @'
{
    int errorCode = 0;
    try
    {
        tag_t bodyTag = NULL_TAG;
        if (!getBodyTag(selection0, bodyTag))
        {
            MoveandCut::theUI->NXMessageBox()->Show("Error", NXOpen::NXMessageBox::DialogTypeWarning, "Select a body first");
            return 1;
        }
        double startPt[3] = {0.0, 0.0, 0.0};
        double endPt[3]   = {100.0, 0.0, 0.0};
        int sMode = 1;
        try { PropertyList* p = enum0->GetProperties(); sMode = p->GetInteger("Value"); delete p; } catch(...) { sMode = 1; }
        switch (sMode)
        {
        case 0: { double b[6]; if (getBodyBBox(selection0, b)) { startPt[0]=(b[0]+b[3])/2; startPt[1]=(b[1]+b[4])/2; startPt[2]=b[5]; } break; }
        case 1: { double b[6]; if (getBodyBBox(selection0, b)) { startPt[0]=(b[0]+b[3])/2; startPt[1]=(b[1]+b[4])/2; startPt[2]=(b[2]+b[5])/2; } break; }
        case 2: { double b[6]; if (getBodyBBox(selection0, b)) { startPt[0]=(b[0]+b[3])/2; startPt[1]=(b[1]+b[4])/2; startPt[2]=b[2]; } break; }
        case 3: { try { PropertyList* p = point0->GetProperties(); NXOpen::Point3d pt = p->GetPoint("Point"); startPt[0]=pt.X; startPt[1]=pt.Y; startPt[2]=pt.Z; delete p; } catch(...) {} break; }
        }
        int eMode = 3;
        try { PropertyList* p = enum01->GetProperties(); eMode = p->GetInteger("Value"); delete p; } catch(...) { eMode = 3; }
        switch (eMode)
        {
        case 0: endPt[0]=0; endPt[1]=0; endPt[2]=0; break;
        case 1: { try { PropertyList* p = point01->GetProperties(); NXOpen::Point3d pt = p->GetPoint("Point"); endPt[0]=pt.X; endPt[1]=pt.Y; endPt[2]=pt.Z; delete p; } catch(...) {} break; }
        case 2: { double b[6]; if (getBodyBBox(selection0, b)) { endPt[0]=(b[0]+b[3])/2; endPt[1]=(b[1]+b[4])/2; endPt[2]=b[2]; } break; }
        case 3: { tag_t wcsTag, mTag; UF_CSYS_ask_wcs(&wcsTag); UF_CSYS_ask_csys_info(wcsTag, &mTag, endPt); break; }
        case 4: { double b[6]; if (getBodyBBox(selection0, b)) { endPt[0]=b[0]; endPt[1]=(b[1]+b[4])/2; endPt[2]=(b[2]+b[5])/2; } break; }
        case 5: { double b[6]; if (getBodyBBox(selection0, b)) { endPt[0]=(b[0]+b[3])/2; endPt[1]=(b[1]+b[4])/2; endPt[2]=(b[2]+b[5])/2; } break; }
        case 6: { double b[6]; if (getBodyBBox(selection0, b)) { endPt[0]=(b[0]+b[3])/2; endPt[1]=b[1]; endPt[2]=(b[2]+b[5])/2; } break; }
        }
        double delta[3] = {100.0, 0.0, 0.0};
                char dbg[512];
        sprintf(dbg, "MoveandCut: delta=(%f,%f,%f)", delta[0], delta[1], delta[2]); UF_UI_write_listing_window(dbg);
        sprintf(dbg, "MoveandCut: start=(%f,%f,%f)", startPt[0], startPt[1], startPt[2]); UF_UI_write_listing_window(dbg);
        sprintf(dbg, "MoveandCut: end=(%f,%f,%f)", endPt[0], endPt[1], endPt[2]); UF_UI_write_listing_window(dbg);
        Part* wp = theSession->Parts()->Work();
        Features::MoveObjectBuilder* builder = wp->BaseFeatures()->CreateMoveObjectBuilder(NULL);
        std::vector<NXOpen::NXObject*> objs;
        std::vector<NXOpen::TaggedObject*> selList = selection0->GetSelectedObjects();
        if (selList.size() > 0) objs.push_back(dynamic_cast<NXOpen::NXObject*>(selList[0]));
        builder->ObjectToMoveObject()->SetArray(objs);
        builder->SetAssociative(false);
        builder->SetMoveParents(false);
        
        // ? 4x4 ??????????
        NXOpen::Matrix4x4 mat;
        memset(mat, 0, sizeof(mat));
        mat[0] = 1.0; mat[5] = 1.0; mat[10] = 1.0; mat[15] = 1.0;
        mat[12] = delta[0]; mat[13] = delta[1]; mat[14] = delta[2];
        builder->SetPreMultiplicationTransform(mat);
        
        if (m_MoveMode == 0)
            builder->SetMoveObjectResult(NXOpen::Features::MoveObjectBuilder::MoveObjectResultOptionsMoveOriginal);
        else
            builder->SetMoveObjectResult(NXOpen::Features::MoveObjectBuilder::MoveObjectResultOptionsCopyOriginal);
        builder->Commit();
        builder->Destroy();
        UF_MODL_update();
        UF_DISP_refresh();
        char msg[256];
        if (m_MoveMode == 0)
            sprintf(msg, "Move OK. Delta: X=%.1f, Y=%.1f, Z=%.1f", delta[0], delta[1], delta[2]);
        else
            sprintf(msg, "Copy OK. Delta: X=%.1f, Y=%.1f, Z=%.1f", delta[0], delta[1], delta[2]);
        MoveandCut::theUI->NXMessageBox()->Show("Result", NXOpen::NXMessageBox::DialogTypeInformation, msg);
    }
    catch(std::exception& ex)
    {
        errorCode = 1;
        MoveandCut::theUI->NXMessageBox()->Show("Error", NXOpen::NXMessageBox::DialogTypeError, ex.what());
    }
    return errorCode;
}
'@

$newBody = @'
{
    int errorCode = 0;
    try
    {
        // Validate selection
        tag_t bodyTag = NULL_TAG;
        if (!getBodyTag(selection0, bodyTag))
        {
            MoveandCut::theUI->NXMessageBox()->Show("Error", NXOpen::NXMessageBox::DialogTypeWarning, "Select a body first");
            return 1;
        }

        // Read start point / end point modes
        double startPt[3] = {0.0, 0.0, 0.0};
        double endPt[3]   = {0.0, 0.0, 0.0};
        int sMode = readEnumIndex(enum0, 1);
        int eMode = readEnumIndex(enum01, 3);

        // Compute startPt
        switch (sMode)
        {
        case 0:
            { double b[6]; if (getBodyBBox(selection0, b)) { startPt[0]=(b[0]+b[3])/2; startPt[1]=(b[1]+b[4])/2; startPt[2]=b[5]; } }
            break;
        case 1:
            { double b[6]; if (getBodyBBox(selection0, b)) { startPt[0]=(b[0]+b[3])/2; startPt[1]=(b[1]+b[4])/2; startPt[2]=(b[2]+b[5])/2; } }
            break;
        case 2:
            { double b[6]; if (getBodyBBox(selection0, b)) { startPt[0]=(b[0]+b[3])/2; startPt[1]=(b[1]+b[4])/2; startPt[2]=b[2]; } }
            break;
        case 3:
            { try { PropertyList* p = point0->GetProperties(); NXOpen::Point3d pt = p->GetPoint("Point"); startPt[0]=pt.X; startPt[1]=pt.Y; startPt[2]=pt.Z; delete p; } catch(...) {} }
            break;
        }

        // Compute endPt
        switch (eMode)
        {
        case 0:
            endPt[0]=0; endPt[1]=0; endPt[2]=0;
            break;
        case 1:
            { try { PropertyList* p = point01->GetProperties(); NXOpen::Point3d pt = p->GetPoint("Point"); endPt[0]=pt.X; endPt[1]=pt.Y; endPt[2]=pt.Z; delete p; } catch(...) {} }
            break;
        case 2:
            { double b[6]; if (getBodyBBox(selection0, b)) { endPt[0]=(b[0]+b[3])/2; endPt[1]=(b[1]+b[4])/2; endPt[2]=b[2]; } }
            break;
        case 3:
            { tag_t wcsTag, mTag; UF_CSYS_ask_wcs(&wcsTag); UF_CSYS_ask_csys_info(wcsTag, &mTag, endPt); }
            break;
        case 4:
            { double b[6]; if (getBodyBBox(selection0, b)) { endPt[0]=b[0]; endPt[1]=(b[1]+b[4])/2; endPt[2]=(b[2]+b[5])/2; } }
            break;
        case 5:
            { double b[6]; if (getBodyBBox(selection0, b)) { endPt[0]=(b[0]+b[3])/2; endPt[1]=(b[1]+b[4])/2; endPt[2]=(b[2]+b[5])/2; } }
            break;
        case 6:
            { double b[6]; if (getBodyBBox(selection0, b)) { endPt[0]=(b[0]+b[3])/2; endPt[1]=b[1]; endPt[2]=(b[2]+b[5])/2; } }
            break;
        }

        // Compute delta = end - start
        double delta[3];
        delta[0] = endPt[0] - startPt[0];
        delta[1] = endPt[1] - startPt[1];
        delta[2] = endPt[2] - startPt[2];

        // Log to listing window
        char dbg[512];
        sprintf(dbg, "MoveandCut: sMode=%d eMode=%d", sMode, eMode); UF_UI_write_listing_window(dbg);
        sprintf(dbg, "MoveandCut: start=(%.3f,%.3f,%.3f)", startPt[0], startPt[1], startPt[2]); UF_UI_write_listing_window(dbg);
        sprintf(dbg, "MoveandCut: end=(%.3f,%.3f,%.3f)", endPt[0], endPt[1], endPt[2]); UF_UI_write_listing_window(dbg);
        sprintf(dbg, "MoveandCut: delta=(%.3f,%.3f,%.3f)", delta[0], delta[1], delta[2]); UF_UI_write_listing_window(dbg);

        // Create MoveObjectBuilder with ModlMotion DeltaXYZ
        Part* wp = theSession->Parts()->Work();
        Features::MoveObjectBuilder* builder = wp->BaseFeatures()->CreateMoveObjectBuilder(NULL);

        // Set objects to move
        std::vector<NXOpen::NXObject*> objs;
        std::vector<NXOpen::TaggedObject*> selList = selection0->GetSelectedObjects();
        if (selList.size() > 0) objs.push_back(dynamic_cast<NXOpen::NXObject*>(selList[0]));
        builder->ObjectToMoveObject()->SetArray(objs);

        // Non-associative, don't move parents
        builder->SetAssociative(false);
        builder->SetMoveParents(false);

        // Use ModlMotion with OptionsDeltaXyz and expression-based delta
        GeometricUtilities::ModlMotion* motion = builder->TransformMotion();
        motion->SetOption(GeometricUtilities::ModlMotion::OptionsDeltaXyz);
        char expr[64];
        sprintf(expr, "%.6f", delta[0]); motion->DeltaXc()->SetRightHandSide(expr);
        sprintf(expr, "%.6f", delta[1]); motion->DeltaYc()->SetRightHandSide(expr);
        sprintf(expr, "%.6f", delta[2]); motion->DeltaZc()->SetRightHandSide(expr);

        // Result: move original or copy
        if (m_MoveMode == 0)
            builder->SetMoveObjectResult(NXOpen::Features::MoveObjectBuilder::MoveObjectResultOptionsMoveOriginal);
        else
            builder->SetMoveObjectResult(NXOpen::Features::MoveObjectBuilder::MoveObjectResultOptionsCopyOriginal);

        // Commit and destroy
        builder->Commit();
        builder->Destroy();

        // Update part and display
        UF_MODL_update();
        UF_DISP_refresh();

        // Show result
        char msg[256];
        if (m_MoveMode == 0)
            sprintf(msg, "Move OK. Delta: X=%.1f, Y=%.1f, Z=%.1f", delta[0], delta[1], delta[2]);
        else
            sprintf(msg, "Copy OK. Delta: X=%.1f, Y=%.1f, Z=%.1f", delta[0], delta[1], delta[2]);
        MoveandCut::theUI->NXMessageBox()->Show("Result", NXOpen::NXMessageBox::DialogTypeInformation, msg);
    }
    catch(std::exception& ex)
    {
        errorCode = 1;
        MoveandCut::theUI->NXMessageBox()->Show("Error", NXOpen::NXMessageBox::DialogTypeError, ex.what());
    }
    return errorCode;
}
'@

Write-Host "Old body length: $($oldBody.Length)"
Write-Host "New body length: $($newBody.Length)"

$idxOld = $content.IndexOf($oldBody)
Write-Host "Old body found at: $idxOld"

if ($idxOld -ge 0) {
    $content = $content.Replace($oldBody, $newBody)
    Write-Host "Body replaced"
}

# Write back
[System.IO.File]::WriteAllText("E:\NX\source\MoveandCut\MoveandCut.cpp", $content, $enc)
Write-Host "File written OK"
